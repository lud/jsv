defmodule JSV.Resolver do
  alias JSV.Helpers.EnumExt
  alias JSV.Key
  alias JSV.Ref
  alias JSV.RNS

  @moduledoc """
  A behaviour describing the implementation of a [guides/build/custom resolver.
  Resolves remote resources when building a JSON schema.
  """

  defmodule Resolved do
    @moduledoc """
    Metadata gathered from a remote schema or a sub-schema.
    """

    # TODO(Draft7-removal) drop parent_ns once we do not support draft-7
    @enforce_keys [:raw, :meta, :vocabularies, :ns, :parent_ns, :rev_path]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            raw: JSV.normal_schema(),
            meta: binary,
            vocabularies: term,
            ns: binary,
            parent_ns: binary
          }
  end

  defmodule Descriptor do
    @enforce_keys [:raw, :meta, :aliases, :ns, :parent_ns, :rev_path]
    defstruct @enforce_keys
    @moduledoc false
  end

  @doc """
  Receives an URI and the options passed in the resolver tuple to `JSV.build/2`
  and returns a result tuple for a raw JSON schema map.

  Returning boolean schemas from resolvers is not supported. You may wrap the
  boolean value in a `$defs` or any other pointer as a workaround.

  Schemas will be normalized using `JSV.Schema.normalize/1`. If the resolver
  returns schema that are already in JSON-decoded form (like a response body
  from an HTTP call) without atoms, module names or structs, the resolver
  implementation can return `{:normal, map}` instead to skip the normalization.
  """
  @callback resolve(uri :: String.t(), opts :: term) :: {:ok, map} | {:normal, map} | {:error, term}

  @derive {Inspect, Application.compile_env(:jsv, :resolver_inspect_derive, except: [:fetch_cache])}
  defstruct chain: [],
            default_meta: nil,
            # fetch_cache is a local cache for the resolver instance. Actual
            # caching of remote resources should be done in each resolver
            # implementation.
            fetch_cache: %{},
            resolved: %{}

  @opaque t :: %__MODULE__{}
  @type resolvable :: Key.ns() | Key.pointer() | Ref.t()

  @doc """
  Returns a new resolver, with the given behaviour implementations, and a
  default meta-schema URL to use with schemas that do not declare a `$schema`
  property.
  """
  @spec chain_of([{module, term}], binary) :: t
  def chain_of([_ | _] = resolvers, default_meta) do
    %__MODULE__{chain: resolvers, default_meta: default_meta}
  end

  @doc false
  @spec put_cached(t, binary | :root, JSV.normal_schema()) :: {:ok, t} | {:error, {:key_exists, term}}
  def put_cached(%__MODULE__{} = rsv, ext_id, raw_schema)
      when is_map(raw_schema) and (is_binary(ext_id) or :root == ext_id) do
    case rsv.fetch_cache do
      %{^ext_id => _} -> {:error, {:key_exists, ext_id}}
      fetch_cache -> {:ok, %{rsv | fetch_cache: Map.put(fetch_cache, ext_id, raw_schema)}}
    end
  end

  @doc """
  Fetches the remote resource into the internal resolver cache and returns a new
  resolver with that updated cache.
  """
  @spec resolve(t, resolvable) :: {:ok, t} | {:error, term}
  def resolve(rsv, resolvable) do
    case check_resolved(rsv, resolvable) do
      :unresolved -> do_resolve(rsv, resolvable)
      :already_resolved -> {:ok, rsv}
    end
  end

  defp do_resolve(rsv, resolvable) do
    with {:ok, raw_schema, rsv} <- ensure_fetched(rsv, resolvable),
         {:ok, identified_schemas} <- scan_schema(raw_schema, external_id(resolvable), rsv.default_meta),
         {:ok, cache_entries} <- create_cache_entries(identified_schemas),
         {:ok, rsv} <- insert_cache_entries(rsv, cache_entries) do
      resolve_meta_loop(rsv, metas_of(cache_entries))
    else
      {:error, _} = err -> err
    end
  end

  defp external_id(:root) do
    :root
  end

  defp external_id(ns) when is_binary(ns) do
    ns
  end

  defp external_id(%Ref{ns: ns}) do
    ns
  end

  defp metas_of(cache_entries) do
    cache_entries
    |> Enum.flat_map(fn
      {_, {:alias_of, _}} -> []
      {_, %{meta: meta}} -> [meta]
    end)
    |> Enum.uniq()
  end

  defp resolve_meta_loop(rsv, []) do
    {:ok, rsv}
  end

  defp resolve_meta_loop(rsv, [nil | tail]) do
    resolve_meta_loop(rsv, tail)
  end

  defp resolve_meta_loop(rsv, [meta | tail]) when is_binary(meta) do
    with :unresolved <- check_resolved(rsv, {:meta, meta}),
         {:ok, raw_schema, rsv} <- ensure_fetched(rsv, meta),
         {:ok, cache_entry} <- create_meta_entry(raw_schema, meta),
         {:ok, rsv} <- insert_cache_entries(rsv, [{{:meta, meta}, cache_entry}]) do
      resolve_meta_loop(rsv, [cache_entry.meta | tail])
    else
      :already_resolved -> resolve_meta_loop(rsv, tail)
      {:error, _} = err -> err
    end
  end

  defp check_resolved(rsv, id) when is_binary(id) or :root == id do
    case rsv do
      %{resolved: %{^id => _}} -> :already_resolved
      _ -> :unresolved
    end
  end

  defp check_resolved(rsv, {:meta, id}) when is_binary(id) do
    case rsv do
      %{resolved: %{{:meta, ^id} => _}} -> :already_resolved
      _ -> :unresolved
    end
  end

  defp check_resolved(rsv, %Ref{ns: ns}) do
    check_resolved(rsv, ns)
  end

  # Extract all $ids and anchors. We receive the top schema.
  #
  # The top schema differs from a subschema in three ways: its `meta` is derived
  # from `$schema` (subschemas inherit it), it is addressable both by its `$id`
  # and by the external id it was fetched with, and it has no parent namespace.
  # The rest (anchor keys, descriptor, recursion) is shared with `scan_subschema`.
  defp scan_schema(top_schema, external_id, default_meta) when not is_nil(external_id) do
    {raw_id, anchor, dynamic_anchor} = extract_keys(top_schema)

    with :ok <- validate_anchor(anchor, "$anchor"),
         :ok <- validate_anchor(dynamic_anchor, "$dynamicAnchor"),
         {:ok, id, id_anchor} <- split_id(raw_id) do
      anchor_names = Enum.reject([id_anchor, anchor], &is_nil/1)
      scan_top_schema(top_schema, external_id, id, anchor_names, dynamic_anchor, default_meta)
    end
  end

  defp scan_top_schema(top_schema, external_id, id, anchor_names, dynamic_anchor, default_meta) do
    # For self references that target "#" or "#some/path" in the document, when
    # the document does not have an id, we will force it (the external id).
    ns = id || external_id
    nss = [id, external_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    # If no metaschema is defined we use the default draft as a fallback. We
    # normalize it because many schemas use
    # "http://json-schema.org/draft-07/schema#" with a trailing "#".
    meta = normalize_meta(Map.get(top_schema, "$schema", default_meta))

    descriptor = %Descriptor{
      raw: top_schema,
      meta: meta,
      # The schema is findable by its $id and/or external id, plus its anchors.
      aliases: nss ++ anchor_keys(nss, anchor_names, dynamic_anchor),
      ns: ns,
      parent_ns: nil,
      rev_path: [external_id]
    }

    scan_schema_pairs(top_schema, ns, nss, meta, [ns], [descriptor])
  end

  # Splits an `$id` into its base URI (used as a namespace) and an optional
  # anchor carried by a plain-name fragment.
  #
  # JSON Schema draft 7 lets `$id` be a bare plain-name fragment ("#foo") to
  # define a location-independent identifier, _i.e._ an anchor (the spec requires
  # such an id to begin with "#"). Later drafts moved that to `$anchor` and
  # forbid non-empty fragments in `$id`, but we accept the draft-7 form for every
  # draft to keep a single code path.
  #
  # - no fragment              id is the base URI
  # - empty fragment ("#")     trimmed
  # - bare plain-name fragment converted to anchor internally
  # - fragment + base URI      invalid (several ids would share one namespace)
  # - JSON pointer fragment    invalid
  defp split_id(nil) do
    {:ok, nil, nil}
  end

  defp split_id(id) when is_binary(id) do
    case URI.parse(id) do
      %{fragment: nil} -> {:ok, id, nil}
      %{fragment: ""} = uri -> {:ok, base_id(uri), nil}
      %{fragment: "/" <> _} -> {:error, {:invalid_id_fragment, id}}
      %{fragment: anchor} = uri -> expect_anchor_like_id(id, base_id(uri), anchor)
    end
  end

  defp split_id(id) do
    {:error, {:invalid_id, id}}
  end

  defp expect_anchor_like_id(_id, nil = _no_base, anchor) do
    {:ok, nil, anchor}
  end

  defp expect_anchor_like_id(id, _base, _anchor) do
    {:error, {:invalid_id_fragment, id}}
  end

  defp base_id(uri) do
    case URI.to_string(%{uri | fragment: nil}) do
      "" -> nil
      base -> base
    end
  end

  # Builds the resolution keys for the anchors a schema defines: regular anchors
  # (from `$anchor` or a plain-name `$id` fragment) and a `$dynamicAnchor`, each
  # addressable in every namespace the schema is known under. A dynamic anchor
  # is also addressable as a regular anchor.
  defp anchor_keys(nss, anchor_names, dynamic_anchor) do
    anchors =
      for new_ns <- nss, a <- anchor_names do
        Key.for_anchor(new_ns, a)
      end

    dynamic_anchors =
      case dynamic_anchor do
        nil -> []
        da -> Enum.flat_map(nss, &[Key.for_dynamic_anchor(&1, da), Key.for_anchor(&1, da)])
      end

    anchors ++ dynamic_anchors
  end

  # Skip descriptor if schema has no identifier ($id/$anchor)
  defp cons_descriptor(%Descriptor{aliases: []}, acc) do
    acc
  end

  defp cons_descriptor(descriptor, acc) do
    [descriptor | acc]
  end

  defp scan_subschema(raw_schema, parent_ns, parent_nss, meta, path, acc) when is_map(raw_schema) do
    {raw_id, anchor, dynamic_anchor} = extract_keys(raw_schema)

    with :ok <- validate_anchor(anchor, "$anchor"),
         :ok <- validate_anchor(dynamic_anchor, "$dynamicAnchor"),
         {:ok, id, id_anchor} <- split_id(raw_id) do
      anchor_names = Enum.reject([id_anchor, anchor], &is_nil/1)

      # A base URI in the $id discards the current namespaces, as the sibling or
      # nested anchors will now only relate to this id. A bare plain-name
      # fragment ($id "#foo") keeps the current namespaces and only adds an
      # anchor.
      {id_aliases, ns, nss} =
        with true <- is_binary(id),
             {:ok, full_id} <- merge_id(parent_ns, id) do
          {[full_id], full_id, [full_id]}
        else
          _ -> {[], parent_ns, parent_nss}
        end

      # We do not check for the meta $schema in subschemas, we only add the
      # parent_ns to the descriptor.
      descriptor = %Descriptor{
        raw: raw_schema,
        meta: meta,
        aliases: id_aliases ++ anchor_keys(nss, anchor_names, dynamic_anchor),
        ns: ns,
        parent_ns: parent_ns,
        rev_path: path
      }

      scan_schema_pairs(raw_schema, ns, nss, meta, path, cons_descriptor(descriptor, acc))
    end
  end

  defp scan_subschema(scalar, _parent_id, _nss, _meta, _path, acc)
       when is_binary(scalar)
       when is_atom(scalar)
       when is_number(scalar) do
    {:ok, acc}
  end

  defp scan_subschema(list, parent_id, nss, meta, path, acc) when is_list(list) do
    list
    |> Enum.with_index()
    |> EnumExt.reduce_ok(acc, fn {item, index}, acc ->
      scan_subschema(item, parent_id, nss, meta, [index | path], acc)
    end)
  end

  defp validate_anchor(anchor, keyword) do
    case anchor do
      nil -> :ok
      anchor when is_binary(anchor) -> :ok
      other -> {:error, {:invalid_anchor, keyword, other}}
    end
  end

  defp extract_keys(schema) do
    id =
      case Map.fetch(schema, "$id") do
        {:ok, id} -> id
        :error -> nil
      end

    anchor =
      case Map.fetch(schema, "$anchor") do
        {:ok, anchor} -> anchor
        :error -> nil
      end

    dynamic_anchor =
      case Map.fetch(schema, "$dynamicAnchor") do
        {:ok, dynamic_anchor} -> dynamic_anchor
        :error -> nil
      end

    {id, anchor, dynamic_anchor}
  end

  # Keywords whose value is a map from user-defined names (or patterns) to
  # subschemas, arrays or other generic maps.
  @generic_map_keywords [
    "$defs",
    "definitions",
    "dependencies",
    "dependentSchemas",
    "patternProperties",
    "properties"
  ]

  defp scan_schema_pairs(schema, parent_id, nss, meta, path, acc) do
    EnumExt.reduce_ok(schema, acc, fn
      {k, v}, acc when k in @generic_map_keywords and is_map(v) ->
        scan_generic_map(v, parent_id, nss, meta, [k | path], acc)

      {ignored, _}, acc when ignored in ["enum", "const", "examples"] ->
        {:ok, acc}

      {k, v}, acc ->
        scan_subschema(v, parent_id, nss, meta, [k | path], acc)
    end)
  end

  defp scan_generic_map(map, parent_id, nss, meta, path, acc) do
    EnumExt.reduce_ok(map, acc, fn {name, subschema}, acc ->
      scan_subschema(subschema, parent_id, nss, meta, [name | path], acc)
    end)
  end

  defp create_cache_entries(identified_schemas) do
    {:ok, Enum.flat_map(identified_schemas, &to_cache_entries/1)}
  end

  defp to_cache_entries(descriptor) do
    %Descriptor{aliases: aliases, meta: meta, raw: raw, ns: ns, parent_ns: parent_ns, rev_path: rev_path} = descriptor

    resolved =
      %Resolved{meta: meta, raw: raw, ns: ns, parent_ns: parent_ns, vocabularies: nil, rev_path: rev_path}

    case aliases do
      [single] -> [{single, resolved}]
      [first | aliases] -> [{first, resolved} | Enum.map(aliases, &{&1, {:alias_of, first}})]
    end
  end

  defp insert_cache_entries(rsv, entries) do
    %__MODULE__{resolved: cache} = rsv

    cache_result =
      EnumExt.reduce_ok(entries, cache, fn {k, resolved}, cache ->
        case cache do
          %{^k => existing} ->
            # Allow a duplicate resolution that is the exact same value as the
            # preexisting copy. This allows a root schema with an $id to reference
            # itself with an external id such as `jsv:module:MODULE`.
            check_duplicated_cache_entry(k, resolved, existing, cache)

          _ ->
            {:ok, Map.put(cache, k, resolved)}
        end
      end)

    with {:ok, cache} <- cache_result do
      {:ok, %{rsv | resolved: cache}}
    end
  end

  defp check_duplicated_cache_entry(k, resolved, existing, cache) do
    case {resolved, existing} do
      {%Resolved{raw: same}, %Resolved{raw: same}} -> {:ok, cache}
      _ -> {:error, {:duplicate_resolution, k}}
    end
  end

  defp create_meta_entry(raw_schema, ext_id) when not is_struct(raw_schema) do
    case fetch_vocabulary_from_raw(raw_schema, ext_id) do
      {:ok, vocabulary} ->
        # Meta entries are only identified by they external URL so the :ns and
        # :raw value should not be used anywhere. We will just put :__meta__ in
        # here so it's easier to debug.
        resolved = %Resolved{
          vocabularies: vocabulary,
          meta: nil,
          ns: :__meta__,
          parent_ns: nil,
          raw: :__meta__,
          rev_path: [ext_id]
        }

        {:ok, resolved}

      :error ->
        {:error, {:undefined_vocabulary, ext_id}}
    end
  end

  defp fetch_vocabulary_from_raw(raw_schema, ext_id) do
    case Map.fetch(raw_schema, "$vocabulary") do
      {:ok, vocab} when is_map(vocab) -> {:ok, vocab}
      :error -> vocabulary_fallback(ext_id)
    end
  end

  defp vocabulary_fallback("http://json-schema.org/draft-07/schema") do
    vocab = %{
      "https://json-schema.org/draft-07/--fallback--vocab/core" => true,
      "https://json-schema.org/draft-07/--fallback--vocab/validation" => true,
      "https://json-schema.org/draft-07/--fallback--vocab/applicator" => true,
      "https://json-schema.org/draft-07/--fallback--vocab/content" => true,
      "https://json-schema.org/draft-07/--fallback--vocab/format-annotation" => true,
      "https://json-schema.org/draft-07/--fallback--vocab/meta-data" => true

      # We do not declare format assertion to have the same behaviour as 2020-12
      # "https://json-schema.org/draft-07/--fallback--vocab/format-assertion" => true,
    }

    {:ok, vocab}
  end

  defp vocabulary_fallback(_) do
    :error
  end

  defp ensure_fetched(rsv, fetchable) do
    with :unfetched <- check_fetched(rsv, fetchable),
         {:ok, ext_id, raw_schema} <- fetch_raw_schema(rsv, fetchable),
         {:ok, rsv} <- put_cached(rsv, ext_id, raw_schema) do
      {:ok, raw_schema, rsv}
    else
      {:already_fetched, raw_schema} -> {:ok, raw_schema, rsv}
      {:error, _} = err -> err
    end
  end

  defp check_fetched(rsv, %Ref{ns: ns}) do
    check_fetched(rsv, ns)
  end

  defp check_fetched(rsv, id) when is_binary(id) when :root == id do
    case rsv do
      %{fetch_cache: %{^id => fetched}} -> {:already_fetched, fetched}
      _ -> :unfetched
    end
  end

  @spec fetch_raw_schema(t, binary | {:meta, binary} | Ref.t()) :: {:ok, binary, JSV.normal_schema()} | {:error, term}
  defp fetch_raw_schema(rsv, {:meta, url}) do
    fetch_raw_schema(rsv, url)
  end

  defp fetch_raw_schema(rsv, url) when is_binary(url) do
    call_chain(rsv.chain, url)
  end

  defp fetch_raw_schema(rsv, %Ref{ns: ns}) do
    fetch_raw_schema(rsv, ns)
  end

  defp call_chain(chain, url) do
    call_chain(chain, url, _err_acc = [])
  end

  defp call_chain([{module, opts} | chain], url, err_acc) do
    case module.resolve(url, opts) do
      {:ok, resolved} when is_map(resolved) ->
        {:ok, url, normalize_resolved(resolved)}

      {:normal, resolved} when is_map(resolved) ->
        {:ok, url, resolved}

      {:error, reason} ->
        call_chain(chain, url, [{module, reason} | err_acc])

      other ->
        raise "invalid return from #{inspect(module)}.resolve/2, expected {:ok, map} or {:error, reason}, got: #{inspect(other)}"
    end
  end

  defp call_chain([], _url, err_acc) do
    {:error, {:resolver_error, :lists.reverse(err_acc)}}
  end

  defp normalize_resolved(map) when is_map(map) do
    JSV.Schema.normalize(map)
  end

  defp merge_id(parent, child) do
    RNS.derive(parent, child)
  end

  # Removes the fragment from the given URL. Accepts nil values
  defp normalize_meta(nil) do
    nil
  end

  defp normalize_meta(meta) do
    case URI.parse(meta) do
      %{fragment: nil} -> meta
      uri -> URI.to_string(%{uri | fragment: nil})
    end
  end

  @doc """
  Returns the $vocabulary property of a schema identified by its namespace.

  The schema must have been resolved previously as a meta-schema (_i.e._ found
  in an $schema property of a resolved schema).
  """
  @spec fetch_vocabulary(t, binary) :: {:ok, %{optional(binary) => boolean}} | {:error, term}
  def fetch_vocabulary(rsv, meta) do
    case fetch_resolved(rsv, {:meta, meta}) do
      {:ok, %Resolved{vocabularies: vocabularies}} -> {:ok, vocabularies}
      {:error, _} = err -> err
    end
  end

  @doc """
  Returns the raw schema identified by the given key if was previously resolved.
  """
  @spec fetch_resolved(t(), resolvable | {:meta, resolvable}) ::
          {:ok, Resolved.t() | {:alias_of, Key.t()}} | {:error, term}
  def fetch_resolved(rsv, {:pointer, _, _} = pointer) do
    fetch_pointer(rsv.resolved, pointer)
  end

  def fetch_resolved(rsv, key) do
    fetch_local(rsv.resolved, key)
  end

  defp fetch_pointer(cache, {:pointer, ns, docpath}) do
    with {:ok, %Resolved{raw: raw, meta: meta, ns: ns, parent_ns: parent_ns, rev_path: rev_path}} <-
           fetch_local(cache, ns, :dealias),
         {:ok, [sub | _] = parent_chain} <- fetch_docpath(raw, docpath),
         :ok <- check_pointed_schema(sub, docpath),
         {:ok, ns, parent_ns} <- derive_docpath_ns(parent_chain, ns, parent_ns) do
      {:ok,
       %Resolved{
         raw: sub,
         meta: meta,
         vocabularies: nil,
         ns: ns,
         parent_ns: parent_ns,
         rev_path: :lists.reverse(docpath, rev_path)
       }}
    else
      {:error, _} = err -> err
    end
  end

  # A JSON pointer can target any value in a schema document, but only actual
  # schemas (maps and booleans) can be resolved as schemas.
  defp check_pointed_schema(sub, _docpath) when is_map(sub) when is_boolean(sub) do
    :ok
  end

  defp check_pointed_schema(sub, docpath) do
    {:error, {:invalid_sub_schema, docpath, sub}}
  end

  defp fetch_local(cache, key, aliases \\ nil) do
    case Map.fetch(cache, key) do
      {:ok, {:alias_of, key}} when aliases == :dealias -> fetch_local(cache, key)
      {:ok, {:alias_of, key}} -> {:ok, {:alias_of, key}}
      {:ok, cached} -> {:ok, cached}
      :error -> {:error, {:unresolved, key}}
    end
  end

  defp fetch_docpath(raw_schema, docpath) do
    case do_fetch_docpath(raw_schema, docpath, []) do
      {:ok, sub} -> {:ok, sub}
      {:error, reason} -> {:error, {:invalid_docpath, docpath, raw_schema, reason}}
    end
  end

  # When fetching a docpath we will create a list of all parents up to the
  # fetched subschema. The top parent is the last item in the list, the fetched
  # subschema is the head.
  #
  # TODO(Draft7-removal) This is to support Draft 7 to define the correct NS for
  # the subschema. We can remove that list building once Draft 7 is not
  # supported anymore.
  defp do_fetch_docpath(list, [h | t], parents) when is_list(list) and is_integer(h) do
    case Enum.fetch(list, h) do
      {:ok, item} -> do_fetch_docpath(item, t, [list | parents])
      :error -> {:error, {:pointer_error, h, list}}
    end
  end

  defp do_fetch_docpath(list, [h | t], parents) when is_list(list) and is_binary(h) do
    case Integer.parse(h) do
      {n, ""} when n >= 0 ->
        case Enum.fetch(list, n) do
          {:ok, item} -> do_fetch_docpath(item, t, [list | parents])
          :error -> {:error, {:pointer_error, h, list}}
        end

      _ ->
        {:error, {:pointer_error, h, list}}
    end
  end

  defp do_fetch_docpath(raw_schema, [h | t], parents) when is_map(raw_schema) and is_binary(h) do
    case Map.fetch(raw_schema, h) do
      {:ok, sub} -> do_fetch_docpath(sub, t, [raw_schema | parents])
      :error -> {:error, {:pointer_error, h, raw_schema}}
    end
  end

  defp do_fetch_docpath(raw_schema, [], parents) do
    {:ok, [raw_schema | parents]}
  end

  # TODO(Draft7-removal) remove derive_docpath_ns/3, this is only to support Draft7 where we
  # must keep the parent_ns around in a %Resolved{}
  defp derive_docpath_ns([%{"$id" => id} | [_ | _] = tail], parent_ns, parent_parent_ns) do
    # Recursion first to go back to the top schema of the docpath
    with {:ok, parent_ns, _parent_parent_ns} <- derive_docpath_ns(tail, parent_ns, parent_parent_ns),
         {:ok, new_ns} <- RNS.derive(parent_ns, id) do
      {:ok, new_ns, parent_ns}
    end
  end

  defp derive_docpath_ns([_sub_no_id | [_ | _] = tail], parent_ns, parent_parent_ns) do
    derive_docpath_ns(tail, parent_ns, parent_parent_ns)
  end

  defp derive_docpath_ns([_single], ns, parent_ns) do
    # Do not derive from the last schema in the list, as `ns, parent_ns` represent that schema itself
    {:ok, ns, parent_ns}
  end
end
