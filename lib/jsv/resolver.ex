defmodule JSV.Resolver do
  alias JSV.Helpers
  alias JSV.Key
  alias JSV.Ref
  alias JSV.RNS
  alias JSV.Vocabulary

  defmodule Resolved do
    # TODO drop parent_ns once we do not support draft-7
    @enforce_keys [:raw, :meta, :vocabularies, :ns, :parent_ns]
    defstruct @enforce_keys
  end

  @draft_202012_vocabulary %{
    "https://json-schema.org/draft/2020-12/vocab/core" => Vocabulary.V202012.Core,
    "https://json-schema.org/draft/2020-12/vocab/validation" => Vocabulary.V202012.Validation,
    "https://json-schema.org/draft/2020-12/vocab/applicator" => Vocabulary.V202012.Applicator,
    "https://json-schema.org/draft/2020-12/vocab/content" => Vocabulary.V202012.Content,
    "https://json-schema.org/draft/2020-12/vocab/format-annotation" => Vocabulary.V202012.Format,
    "https://json-schema.org/draft/2020-12/vocab/format-assertion" => {Vocabulary.V202012.Format, assert: true},
    "https://json-schema.org/draft/2020-12/vocab/meta-data" => Vocabulary.V202012.MetaData,
    "https://json-schema.org/draft/2020-12/vocab/unevaluated" => Vocabulary.V202012.Unevaluated
  }
  @draft7_vocabulary %{
    "https://json-schema.org/draft-07/--fallback--vocab/core" => Vocabulary.Draft7.Core,
    "https://json-schema.org/draft-07/--fallback--vocab/validation" => Vocabulary.Draft7.Validation,
    "https://json-schema.org/draft-07/--fallback--vocab/applicator" => Vocabulary.Draft7.Applicator,
    # "https://json-schema.org/draft-07/--fallback--vocab/content" => Vocabulary.Draft7.Content,
    "https://json-schema.org/draft-07/--fallback--vocab/format-annotation" => Vocabulary.Draft7.Format,
    "https://json-schema.org/draft-07/--fallback--vocab/format-assertion" => {Vocabulary.Draft7.Format, assert: true}
    # "https://json-schema.org/draft-07/--fallback--vocab/meta-data" => Vocabulary.Draft7.MetaData,
    # "https://json-schema.org/draft-07/--fallback--vocab/unevaluated" => Vocabulary.Draft7.Unevaluated
  }
  @draft7_vocabulary_keyword_fallback Map.new(@draft7_vocabulary, fn {k, _mod} -> {k, true} end)

  @vocabulary %{} |> Map.merge(@draft_202012_vocabulary) |> Map.merge(@draft7_vocabulary)

  @fix_host "jsv-no-host"
  @fix_scheme "jsv-no-scheme"

  # @derive {Inspect, only: [:resolved,  :opts]}
  @enforce_keys [:root]
  defstruct [
    :ns,
    :root,
    opts: %{resolver: UnknownResolver, default_draft: nil},
    fetch_cache: %{},
    resolved: %{},
    vocabularies: %{}
  ]

  @opaque t :: %__MODULE__{}

  # TODO build new_root as set_root(new(opts), raw_schema)
  def new_root(raw_schema, opts_map) when is_map(raw_schema) do
    # Bootstrap of the recursive resolving of schemas, metaschemas and
    # anchors/$ids. We just need to set the :root value in the context as the
    # $id (or `:root` atom if not set) of the top schema.

    root_ns = Map.get(raw_schema, "$id", :root)
    rsv = %__MODULE__{root: root_ns, opts: opts_map}

    with {:ok, rsv} <- resolve(rsv, {:prefetched, root_ns, raw_schema}),
         {:ok, vocabularies} <- fetch_vocabularies_for(rsv, root_ns) do
      {:ok, %__MODULE__{rsv | ns: root_ns, vocabularies: vocabularies}}
    else
      {:error, _} = err -> err
    end
  end

  def resolve(rsv, resolvable) do
    case check_resolved(rsv, resolvable) do
      :unresolved -> do_resolve(rsv, resolvable)
      :already_resolved -> {:ok, rsv}
    end
  end

  defp do_resolve(rsv, resolvable) do
    with {:ok, raw_schema, rsv} <- ensure_fetched(rsv, resolvable),
         {:ok, identified_schemas} <- scan_schema(raw_schema, external_id(resolvable), rsv.opts.default_draft),
         {:ok, cache_entries} <- create_cache_entries(identified_schemas),
         {:ok, rsv} <- insert_cache_entries(rsv, cache_entries) do
      resolve_meta_loop(rsv, metas_of(cache_entries))
    else
      {:error, _} = err -> err
    end
  end

  defp metas_of(cache_entries) do
    cache_entries
    |> Enum.flat_map(fn
      {_, {:alias_of, _}} -> []
      {_, v} -> [v.meta]
    end)
    |> Enum.uniq()
  end

  defp resolve_meta_loop(rsv, []) do
    {:ok, rsv}
  end

  defp resolve_meta_loop(rsv, [meta | tail]) when is_binary(meta) do
    with :unresolved <- check_resolved(rsv, {:meta, meta}),
         {:ok, raw_schema, rsv} <- ensure_fetched(rsv, meta),
         {:ok, cache_entry} <- create_meta_entry(raw_schema),
         {:ok, rsv} <- insert_cache_entries(rsv, [{{:meta, meta}, cache_entry}]) do
      resolve_meta_loop(rsv, [cache_entry.meta | tail])
    else
      :already_resolved -> resolve_meta_loop(rsv, tail)
      {:error, _} = err -> err
    end
  end

  defp check_resolved(rsv, {:prefetched, id, _}) do
    check_resolved(rsv, id)
  end

  defp check_resolved(rsv, {:dynamic_anchor, ns, _}) do
    check_resolved(rsv, ns)
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

  # Extract all $ids and achors. We receive the top schema
  defp scan_schema(top_schema, external_id, default_draft) when not is_nil(external_id) do
    {id, anchor, dynamic_anchor} = extract_keys(top_schema)

    # For self references that target "#" or "#some/path" in the document, when
    # the document does not have an id, we will force it. This is for the root
    # document only.

    id = ensure_uri_ns(id)

    ns =
      case id do
        nil -> external_id
        _ -> id
      end

    nss = [id, external_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    # Anchor needs to be resolved from the $id or the external ID (an URL) if
    # set.
    anchors =
      case anchor do
        nil -> []
        _ -> Enum.map(nss, &Key.for_anchor(&1, anchor))
      end

    dynamic_anchors =
      case dynamic_anchor do
        # a dynamic anchor is also adressable as a regular anchor for the given namespace
        nil -> []
        _ -> Enum.flat_map(nss, &[Key.for_dynamic_anchor(&1, dynamic_anchor), Key.for_anchor(&1, dynamic_anchor)])
      end

    # The schema will be findable by its $id or external id.
    id_aliases = nss
    aliases = id_aliases ++ anchors ++ dynamic_anchors

    # If no metaschema is defined we will use the default draft as a fallback
    meta = Map.get(top_schema, "$schema", default_draft)

    top_descriptor = %{raw: top_schema, meta: meta, aliases: aliases, ns: ns, parent_ns: nil}
    acc = [top_descriptor]

    scan_map_values(top_schema, id, nss, meta, acc)
  end

  defp ensure_uri_ns(nil) do
    nil
  end

  defp ensure_uri_ns("urn:" <> _ = urn) do
    urn
  end

  defp ensure_uri_ns(url) do
    uri =
      case URI.parse(url) do
        %{scheme: nil, host: nil} = uri -> %URI{uri | scheme: @fix_scheme, host: @fix_host}
        %{scheme: nil} = uri -> %URI{uri | scheme: @fix_scheme}
        %{host: nil} = uri -> %URI{uri | host: @fix_host}
        uri -> uri
      end

    URI.to_string(uri)
  end

  defp scan_subschema(raw_schema, ns, nss, meta, acc) when is_map(raw_schema) do
    # If the subschema defines an id, we will discard the current namespaces, as
    # the sibling or nested anchors will now only relate to this id

    parent_ns = ns

    {id, anchors, dynamic_anchor} =
      case extract_keys(raw_schema) do
        # ID that is a fragment is replaced as an anchor
        {"#" <> frag_id, anchor, dynamic_anchor} -> {nil, [frag_id | List.wrap(anchor)], dynamic_anchor}
        {id, anchor, dynamic_anchor} -> {id, List.wrap(anchor), dynamic_anchor}
      end

    {id_aliases, ns, nss} =
      with true <- is_binary(id),
           {:ok, full_id} <- merge_id(ns, id) do
        {[full_id], full_id, [full_id]}
      else
        _ -> {[], ns, nss}
      end

    anchors =
      for new_ns <- nss, a <- anchors do
        Key.for_anchor(new_ns, a)
      end

    dynamic_anchors =
      case dynamic_anchor do
        nil -> []
        # a dynamic anchor is also adressable as a regular anchor for the given namespace
        da -> Enum.flat_map(nss, &[Key.for_dynamic_anchor(&1, da), Key.for_anchor(&1, da)])
      end

    # We do not check for the $meta is subschemas, we only add the parent_one to
    # the descriptor.
    #

    acc =
      case(id_aliases ++ anchors ++ dynamic_anchors) do
        [] ->
          acc

        aliases ->
          descriptor = %{raw: raw_schema, meta: meta, aliases: aliases, ns: ns, parent_ns: parent_ns}
          [descriptor | acc]
      end

    scan_map_values(raw_schema, ns, nss, meta, acc)
  end

  defp scan_subschema(scalar, _parent_id, _nss, _meta, acc)
       when is_binary(scalar)
       when is_atom(scalar)
       when is_number(scalar) do
    {:ok, acc}
  end

  defp scan_subschema(list, parent_id, nss, meta, acc) when is_list(list) do
    Helpers.reduce_ok(list, acc, fn item, acc -> scan_subschema(item, parent_id, nss, meta, acc) end)
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

  defp scan_map_values(schema, parent_id, nss, meta, acc) do
    Helpers.reduce_ok(schema, acc, fn
      {"properties", props}, acc when is_map(props) ->
        scan_map_values(props, parent_id, nss, meta, acc)

      {"properties", props}, _ ->
        raise "TODO what are those properties?: #{inspect(props)}"

      {ignored, _}, _ when ignored in ["enum", "const"] ->
        {:ok, acc}

      {_k, v}, acc ->
        scan_subschema(v, parent_id, nss, meta, acc)
    end)
  end

  defp create_cache_entries(identified_schemas) do
    {:ok, Enum.flat_map(identified_schemas, &to_cache_entries/1)}
  end

  defp to_cache_entries(descriptor) do
    %{aliases: aliases, meta: meta, raw: raw, ns: ns, parent_ns: parent_ns} = descriptor

    resolved = %Resolved{meta: meta, raw: raw, ns: ns, parent_ns: parent_ns, vocabularies: nil}

    case aliases do
      [single] -> [{single, resolved}]
      [first | aliases] -> [{first, resolved} | Enum.map(aliases, &{&1, {:alias_of, first}})]
    end
  end

  defp insert_cache_entries(rsv, entries) do
    %{resolved: cache} = rsv

    cache_result =
      Helpers.reduce_ok(entries, cache, fn {k, v}, cache ->
        case cache do
          %{^k => _} -> {:error, {:duplicate_resolution, k}}
          _ -> {:ok, Map.put(cache, k, v)}
        end
      end)

    with {:ok, cache} <- cache_result do
      {:ok, %__MODULE__{rsv | resolved: cache}}
    end
  end

  defp create_meta_entry(raw_schema) when not is_struct(raw_schema) do
    vocabulary = Map.get(raw_schema, "$vocabulary")
    # TODO we should not even recursively download metaschemas?

    # Do not default to latest meta on meta schema as we will not use it anyway
    meta = Map.get(raw_schema, "$schema", nil)
    id = Map.fetch!(raw_schema, "$id")

    case load_vocabularies(vocabulary, id) do
      {:ok, vocabularies} ->
        {:ok, %Resolved{vocabularies: vocabularies, meta: meta, ns: id, parent_ns: nil, raw: :__meta__}}

      {:error, _} = err ->
        err
    end
  end

  defp external_id({:prefetched, ext_id, _}) do
    ext_id
  end

  defp external_id(%Ref{ns: ns}) do
    ns
  end

  defp ensure_fetched(rsv, {:prefetched, _, raw_schema}) do
    {:ok, raw_schema, rsv}
  end

  defp ensure_fetched(rsv, fetchable) do
    with :unfetched <- check_fetched(rsv, fetchable),
         {:ok, ext_id, raw_schema} <- fetch_raw_schema(rsv, fetchable) do
      %{fetch_cache: cache} = rsv
      {:ok, raw_schema, %__MODULE__{rsv | fetch_cache: put_cache(cache, ext_id, raw_schema)}}
    else
      {:already_fetched, raw_schema} -> {:ok, raw_schema, rsv}
      {:error, _} = err -> err
    end
  end

  defp put_cache(cache, ext_id, raw_schema) do
    Map.put(cache, ext_id, raw_schema)
  end

  defp check_fetched(rsv, %Ref{ns: ns}) do
    check_fetched(rsv, ns)
  end

  defp check_fetched(rsv, id) when is_binary(id) do
    case rsv do
      %{fetch_cache: %{^id => fetched}} -> {:already_fetched, fetched}
      _ -> :unfetched
    end
  end

  def fetch_raw_schema(rsv, {:meta, url}) do
    fetch_raw_schema(rsv, url)
  end

  def fetch_raw_schema(rsv, url) when is_binary(url) do
    call_resolver(rsv.opts.resolver, url)
  end

  def fetch_raw_schema(rsv, %Ref{ns: ns}) do
    fetch_raw_schema(rsv, ns)
  end

  defp call_resolver(resolver, url) do
    case resolver.resolve(url) do
      {:ok, resolved} -> {:ok, url, resolved}
      {:error, _} = err -> err
    end
  end

  defp merge_id(nil, child) do
    RNS.derive(child, "")
  end

  defp merge_id(parent, child) do
    RNS.derive(parent, child)
  end

  # This function is called for all schemas, but only metaschemas should define
  # vocabulary, so nil is a valid vocabulary map. It will not be looked up for
  # normal schemas, and metaschemas without vocabulary should have a default
  # vocabulary in the library.
  defp load_vocabularies(nil, id)
       when id in [
              "http://json-schema.org/draft-07/schema",
              "http://json-schema.org/draft-07/schema#"
            ] do
    load_vocabularies(@draft7_vocabulary_keyword_fallback, id)
  end

  defp load_vocabularies(nil, id) do
    raise "Schema with $id #{inspect(id)} does not define vocabularies"
    {:ok, nil}
  end

  defp load_vocabularies(map, _) when is_map(map) do
    known =
      Enum.flat_map(map, fn {uri, required} ->
        case Map.fetch(@vocabulary, uri) do
          {:ok, module} -> [module]
          :error when required -> throw({:unknown_vocabulary, uri})
          :error -> []
        end
      end)

    {:ok, sort_vocabularies(known)}
  catch
    {:unknown_vocabulary, uri} -> {:error, {:unknown_vocabulary, uri}}
  end

  defp sort_vocabularies(modules) do
    Enum.sort_by(modules, fn
      {module, _} -> module.priority()
      module -> module.priority()
    end)
  end

  def fetch_vocabularies_for(rsv, %Resolved{meta: meta}) do
    fetch_vocabularies_of(rsv, meta)
  end

  def fetch_vocabularies_for(rsv, ns) do
    # The vocabularies are defined by the meta schema, so we do a double fetch
    with {:ok, %{meta: meta}} <- deref_resolved(rsv, ns) do
      fetch_vocabularies_of(rsv, meta)
    end
  end

  defp fetch_vocabularies_of(rsv, meta) do
    case deref_resolved(rsv, {:meta, meta}) do
      {:ok, %{vocabularies: vocabularies}} -> {:ok, vocabularies}
      {:error, _} = err -> err
    end
  end

  IO.warn("@TODO use a single function for deref_resolved and fetch_resolved, it is confusing for now")

  defp deref_resolved(%{resolved: cache} = rsv, key) do
    case Map.fetch(cache, key) do
      {:ok, {:alias_of, key}} -> deref_resolved(rsv, key)
      {:ok, cached} -> {:ok, cached}
      :error -> {:error, {:missed_cache, key}}
    end
  end

  def fetch_resolved(rsv, binary) when is_binary(binary) do
    do_fetch_resolved(rsv, binary)
  end

  def fetch_resolved(rsv, :root) do
    do_fetch_resolved(rsv, :root)
  end

  def fetch_resolved(rsv, {:pointer, ns, docpath}) do
    with {:ok, %Resolved{raw: raw, meta: meta, ns: ns, parent_ns: parent_ns}} <- deref_resolved(rsv, ns),
         {:ok, [sub | _] = subs} <- fetch_docpath(raw, docpath),
         {:ok, ns, parent_ns} <- derive_docpath_ns(subs, ns, parent_ns) do
      {:ok, %Resolved{raw: sub, meta: meta, vocabularies: nil, ns: ns, parent_ns: parent_ns}}
    else
      {:error, _} = err -> err
    end
  end

  def fetch_resolved(rsv, {:dynamic_anchor, _, _} = k) do
    do_fetch_resolved(rsv, k)
  end

  def fetch_resolved(rsv, {:anchor, _, _} = k) do
    do_fetch_resolved(rsv, k)
  end

  defp do_fetch_resolved(%{resolved: cache}, key) do
    case Map.fetch(cache, key) do
      {:ok, cached} -> {:ok, cached}
      :error -> {:error, {:missed_cache, key}}
    end
  end

  defp fetch_docpath(raw_schema, docpath) do
    case do_fetch_docpath(raw_schema, docpath, []) do
      {:ok, sub} -> {:ok, sub}
      :error -> {:error, {:invalid_docpath, docpath, raw_schema}}
    end
  end

  defp do_fetch_docpath(list, [h | t], parents) when is_list(list) and is_integer(h) do
    with {:ok, item} <- Enum.fetch(list, h) do
      do_fetch_docpath(item, t, [list | parents])
    end
  end

  defp do_fetch_docpath(raw_schema, [h | t], parents) when is_map(raw_schema) and is_binary(h) do
    with {:ok, sub} <- Map.fetch(raw_schema, h) do
      do_fetch_docpath(sub, t, [raw_schema | parents])
    end
  end

  defp do_fetch_docpath(raw_schema, [], parents) do
    {:ok, [raw_schema | parents]}
  end

  # TODO remove  derive_docpath_ns/3, this is only to support Draft7
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
