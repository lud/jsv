defmodule JSV.Builder do
  alias JSV.BooleanSchema
  alias JSV.Helpers.EnumExt
  alias JSV.Key
  alias JSV.Ref
  alias JSV.Resolver
  alias JSV.Resolver.Resolved
  alias JSV.RNS
  alias JSV.Root
  alias JSV.Schema
  alias JSV.Validator
  alias JSV.Vocabulary

  @moduledoc """
  Internal logic to build raw schemas into `JSV.Root` structs.
  """

  @derive {Inspect, except: []}
  @enforce_keys [:resolver]
  defstruct [
    :resolver,
    staged: [],
    vocabularies: nil,
    vocabulary_impls: %{},
    ns: nil,
    parent_ns: nil,
    opts: [],
    current_rev_path: []
  ]

  @type t :: %__MODULE__{resolver: term, staged: [term], vocabularies: term, ns: term, parent_ns: term, opts: term}
  @type resolvable :: Resolver.resolvable()
  @type buildable :: {:resolved, resolvable} | resolvable
  @type path_segment :: binary | non_neg_integer | atom | {atom, term}

  @doc """
  Returns a new builder. Builders are not reusable ; a fresh builder must be
  made for each different root schema.
  """
  @spec new(keyword) :: t
  def new(opts) do
    {resolver_chain, opts} = Keyword.pop!(opts, :resolvers)
    {default_meta, opts} = Keyword.pop!(opts, :default_meta)

    # beware, the :vocabularies option is not the final value of the
    # :vocabularies key in the Builder struct. It's a configuration option to
    # build the final value. This option is kept around in the :vocabulary_impls
    # struct key after being merged on top of the default implementations.
    {add_vocabulary_impls, opts} = Keyword.pop!(opts, :vocabularies)
    vocabulary_impls = build_vocabulary_impls(add_vocabulary_impls)

    resolver = Resolver.chain_of(resolver_chain, default_meta)
    struct!(__MODULE__, resolver: resolver, opts: opts, vocabulary_impls: vocabulary_impls)
  end

  @doc """
  Builds the given raw schema into a `JSV.Root` struct.
  """
  @spec build(t, JSV.raw_schema()) :: {:ok, JSV.Root.t()} | {:error, term}
  def build(_builder, valid?) when is_boolean(valid?) do
    {:ok, %Root{raw: valid?, root_key: :root, validators: %{root: BooleanSchema.of(valid?, [:root])}}}
  end

  def build(builder, module) when is_atom(module) do
    build_root(builder, module.schema())
  rescue
    e in UndefinedFunctionError -> {:error, e}
  end

  def build(builder, raw_schema) when is_map(raw_schema) do
    build_root(builder, raw_schema)
  end

  @spec build_root(t, map) :: {:ok, JSV.Root.t()} | {:error, term}
  defp build_root(builder, raw_schema) do
    raw_schema = Schema.normalize(raw_schema)

    with {:ok, root_key, resolver} <- Resolver.resolve_root(builder.resolver, raw_schema),
         builder = stage_build(%__MODULE__{builder | resolver: resolver}, root_key),
         {:ok, validators} <- build_all(builder) do
      {:ok, %Root{raw: raw_schema, validators: validators, root_key: root_key}}
    else
      {:error, _} = err -> err
    end
  end

  @doc """
  Adds a new key to be built later. A key is generatlly derived from a
  reference.
  """
  @spec stage_build(t, buildable) :: t()
  def stage_build(%{staged: staged} = builder, buildable) do
    %__MODULE__{builder | staged: append_unique(staged, buildable)}
  end

  defp append_unique([same | t], same) do
    [same | t]
  end

  defp append_unique([h | t], key) do
    [h | append_unique(t, key)]
  end

  defp append_unique([], key) do
    [key]
  end

  @doc """
  Ensures that the remote resource that the given reference or key points to is
  fetched in the builder internal cache
  """
  @spec ensure_resolved(t, resolvable) :: {:ok, t} | {:error, {:resolver_error, term}}
  def ensure_resolved(%{resolver: resolver} = builder, resolvable) do
    case Resolver.resolve(resolver, resolvable) do
      {:ok, resolver} -> {:ok, %__MODULE__{builder | resolver: resolver}}
      {:error, _} = err -> err
    end
  end

  @doc """
  Returns the raw schema identified by the given key. Use `ensure_resolved/2`
  before if the resource may not have been fetched.
  """
  @spec fetch_resolved(t, Key.t()) :: {:ok, JSV.raw_schema()} | {:error, term}
  def fetch_resolved(%{resolver: resolver}, key) do
    Resolver.fetch_resolved(resolver, key)
  end

  defp take_staged(%{staged: []}) do
    :empty
  end

  defp take_staged(%{staged: [staged | tail]} = builder) do
    {staged, %__MODULE__{builder | staged: tail}}
  end

  # * all_validators represent the map of schema_id_or_ref => validators for
  #   this schema
  # * schema validators is the validators corresponding to one schema document
  # * mod_validators are the created validators from part of a schema
  #   keywords+values and a vocabulary module

  defp build_all(builder) do
    build_all(builder, %{})
  catch
    {:thrown_build_error, reason} -> {:error, reason}
  end

  defp build_all(builder, all_validators) do
    # We split the buildables in three cases:
    # - One dynamic refs will lead to build all existing dynamic refs not
    #   already built.
    # - Resolvables such as ID and Ref will be resolved and turned into
    #   :resolved tuples.
    # - :resolved tuples assume to be already resolved and will be built into
    #   validators.
    #
    # We need to do that 2-pass in the stage list because some resolvables
    # (dynamic refs) lead to stage and build multiple validators.

    case take_staged(builder) do
      {{:resolved, vkey}, builder} ->
        with :buildable <- check_not_built(all_validators, vkey),
             {:ok, resolved} <- Resolver.fetch_resolved(builder.resolver, vkey),
             {:ok, schema_validators, builder} <- build_resolved(builder, resolved) do
          build_all(builder, register_validator(all_validators, vkey, schema_validators))
        else
          {:already_built, _} -> build_all(builder, all_validators)
          {:error, _} = err -> err
        end

      {%Ref{dynamic?: true}, builder} ->
        builder = stage_all_dynamic(builder)
        build_all(builder, all_validators)

      {resolvable, builder} when is_binary(resolvable) when is_struct(resolvable, Ref) when :root == resolvable ->
        with :buildable <- check_not_built(all_validators, Key.of(resolvable)),
             {:ok, builder} <- resolve_and_stage(builder, resolvable) do
          build_all(builder, all_validators)
        else
          {:already_built, _} -> build_all(builder, all_validators)
          {:error, _} = err -> err
        end

      # Finally there is nothing more to build
      :empty ->
        {:ok, all_validators}
    end
  end

  defp register_validator(all_validators, vkey, schema_validators) do
    Map.put(all_validators, vkey, schema_validators)
  end

  defp resolve_and_stage(builder, resolvable) do
    vkey = Key.of(resolvable)

    case ensure_resolved(builder, resolvable) do
      {:ok, new_builder} -> {:ok, stage_build(new_builder, {:resolved, vkey})}
      {:error, _} = err -> err
    end
  end

  # TODO we should only stage for build the dynamic anchors that have the same
  # anchor name as the ref. Not a big deal since we will not waste time to
  # rebuilt what is arealdy built thanks to check_not_built/2 -> :already_built.
  defp stage_all_dynamic(builder) do
    # To build all dynamic references we tap into the resolver. The resolver
    # also conveniently allows to fetch by its own keys ({:dynamic_anchor, _,
    # _}) instead of passing the original ref.
    #
    # Everytime we encounter a dynamic ref in build_all/2 we insert all dynamic
    # references into the staged list. But if we insert the ref itself it will
    # lead to an infinite loop, since we do that when we find a ref in this
    # loop.
    #
    # So instead of inserting the ref we insert the Key, and the Key module and
    # Resolver accept to work with that kind of schema identifier (that is,
    # {:dynamic_anchor, _, _} tuple).
    #
    # New items only come up when we build subschemas by staging a ref in the
    # builder.
    #
    # But to keep it clean we scan the whole list every time.
    dynamic_buildables =
      Enum.flat_map(builder.resolver.resolved, fn
        {{:dynamic_anchor, _, _} = vkey, _resolved} -> [{:resolved, vkey}]
        _ -> []
      end)

    %__MODULE__{builder | staged: dynamic_buildables ++ builder.staged}
  end

  defp check_not_built(all_validators, vkey) do
    case is_map_key(all_validators, vkey) do
      true -> {:already_built, vkey}
      false -> :buildable
    end
  end

  defp build_resolved(builder, {:alias_of, key}) do
    # Keep the alias in the validators but ensure the value it points to gets
    # built too by staging it.
    #
    # The alias returned by the resolver is a key, it is not a binary or a
    # %Ref{} staged by some vocabulary. (Thouh a binary is a valid key). So we
    # must stage it as already resolved.
    #
    # Since this key is provided by the resolver we have the guarantee that the
    # alias target is actually resolved already.
    {:ok, {:alias_of, key}, stage_build(builder, {:resolved, key})}
  end

  defp build_resolved(builder, resolved) do
    %Resolved{meta: meta, ns: ns, parent_ns: parent_ns, rev_path: rev_path} = resolved

    with {:ok, raw_vocabularies} <- fetch_vocabulary(builder, meta),
         {:ok, vocabularies} <- load_vocabularies(builder, raw_vocabularies) do
      builder = %__MODULE__{builder | vocabularies: vocabularies, ns: ns, parent_ns: parent_ns}
      # Here we call `do_build_sub` directly instead of `build_sub` because in
      # this case, if the sub schema has an $id we want to actually build it
      # and not register an alias.
      #
      # We set the current_rev_path on the builder because if the vocabulary
      # module recursively calls build_sub we will need the current path
      # later.

      with_current_path(builder, rev_path, fn builder ->
        do_build_sub(resolved.raw, rev_path, builder)
      end)
    else
      {:error, _} = err ->
        err
    end
  end

  defp with_current_path(builder, rev_path, fun) do
    previous_rev_path = builder.current_rev_path

    next = %__MODULE__{builder | current_rev_path: rev_path}

    case fun.(next) do
      {:ok, value, %__MODULE__{} = new_builder} ->
        {:ok, value, %__MODULE__{new_builder | current_rev_path: previous_rev_path}}
    end
  end

  defp fetch_vocabulary(builder, meta) do
    Resolver.fetch_vocabulary(builder.resolver, meta)
  end

  @doc """
  Builds a subschema. Called from vocabulary modules to build nested schemas
  such as in properties, if/else, items, etc.
  """
  @spec build_sub(JSV.raw_schema(), [path_segment()], t) :: {:ok, Validator.validator(), t} | {:error, term}
  def build_sub(%{"$id" => id}, _add_rev_path, builder) do
    with {:ok, key} <- RNS.derive(builder.ns, id) do
      {:ok, {:alias_of, key}, stage_build(builder, key)}
    end
  end

  def build_sub(raw_schema, add_rev_path, builder) when is_map(raw_schema) when is_boolean(raw_schema) do
    new_rev_path = add_rev_path ++ builder.current_rev_path

    with_current_path(builder, new_rev_path, fn builder ->
      do_build_sub(raw_schema, new_rev_path, builder)
    end)
  end

  defp do_build_sub(raw_schema, rev_path, builder) when is_map(raw_schema) do
    {_leftovers, schema_validators, builder} =
      Enum.reduce(builder.vocabularies, {raw_schema, [], builder}, fn module_or_tuple,
                                                                      {remaining_pairs, schema_validators, builder} ->
        # For one vocabulary module we reduce over the raw schema keywords to
        # accumulate the validator map.
        {module, init_opts} = mod_and_init_opts(module_or_tuple)

        {remaining_pairs, mod_validators, builder} =
          build_mod_validators(remaining_pairs, module, init_opts, builder, raw_schema)

        case mod_validators do
          :ignore -> {remaining_pairs, schema_validators, builder}
          _ -> {remaining_pairs, [{module, mod_validators} | schema_validators], builder}
        end
      end)

    # TODO we should warn if the dialect did not pick all elements from the
    # schema. But this should be opt-in. We should have an option that accepts a
    # fun, so an user of the library could raise, log, or pass.
    #
    #     case leftovers do
    #       [] -> :ok
    #       other -> IO.warn("got some leftovers: #{inspect(other)}", [])
    #     end

    # Reverse the list to keep the priority order from builder.vocabularies
    schema_validators = :lists.reverse(schema_validators)

    {:ok, %JSV.Subschema{validators: schema_validators, schema_path: rev_path}, builder}
  end

  defp do_build_sub(valid?, rev_path, builder) when is_boolean(valid?) do
    {:ok, BooleanSchema.of(valid?, rev_path), builder}
  end

  defp mod_and_init_opts({module, opts}) when is_atom(module) and is_list(opts) do
    {module, opts}
  end

  defp mod_and_init_opts(module) when is_atom(module) do
    {module, []}
  end

  defp build_mod_validators(raw_pairs, module, init_opts, builder, raw_schema) when is_map(raw_schema) do
    {leftovers, mod_acc, builder} =
      Enum.reduce(raw_pairs, {[], module.init_validators(init_opts), builder}, fn pair, {leftovers, mod_acc, builder} ->
        # "keyword" refers to the schema keywod, e.g. "type", "properties", etc,
        # supported by a vocabulary.

        case module.handle_keyword(pair, mod_acc, builder, raw_schema) do
          {:ok, mod_acc, builder} -> {leftovers, mod_acc, builder}
          :ignore -> {[pair | leftovers], mod_acc, builder}
          {:error, reason} -> throw({:thrown_build_error, reason})
        end
      end)

    {leftovers, module.finalize_validators(mod_acc), builder}
  end

  @spec vocabulary_enabled?(t, module) :: boolean
  def vocabulary_enabled?(builder, vocab) do
    Enum.find_value(builder.vocabularies, false, fn
      ^vocab -> true
      {^vocab, _} -> true
      _ -> false
    end)
  end

  @vocabulary_impls %{
    # Draft 2020-12
    "https://json-schema.org/draft/2020-12/vocab/core" => Vocabulary.V202012.Core,
    "https://json-schema.org/draft/2020-12/vocab/validation" => Vocabulary.V202012.Validation,
    "https://json-schema.org/draft/2020-12/vocab/applicator" => Vocabulary.V202012.Applicator,
    "https://json-schema.org/draft/2020-12/vocab/content" => Vocabulary.V202012.Content,
    "https://json-schema.org/draft/2020-12/vocab/format-annotation" => Vocabulary.V202012.Format,
    "https://json-schema.org/draft/2020-12/vocab/format-assertion" => {Vocabulary.V202012.Format, assert: true},
    "https://json-schema.org/draft/2020-12/vocab/meta-data" => Vocabulary.V202012.MetaData,
    "https://json-schema.org/draft/2020-12/vocab/unevaluated" => Vocabulary.V202012.Unevaluated,

    # Draft 7 does not define vocabularies. The $vocabulary content is made-up
    # by the resolver so we can use the same architecture for keyword dispatch
    # and allow user overrides.
    "https://json-schema.org/draft-07/--fallback--vocab/core" => Vocabulary.V7.Core,
    "https://json-schema.org/draft-07/--fallback--vocab/validation" => Vocabulary.V7.Validation,
    "https://json-schema.org/draft-07/--fallback--vocab/applicator" => Vocabulary.V7.Applicator,
    "https://json-schema.org/draft-07/--fallback--vocab/content" => Vocabulary.V7.Content,
    "https://json-schema.org/draft-07/--fallback--vocab/format-annotation" => Vocabulary.V7.Format,
    "https://json-schema.org/draft-07/--fallback--vocab/format-assertion" => {Vocabulary.V7.Format, assert: true},
    "https://json-schema.org/draft-07/--fallback--vocab/meta-data" => Vocabulary.V7.MetaData
  }

  defp default_vocabulary_impls do
    @vocabulary_impls
  end

  defp build_vocabulary_impls(user_mapped) do
    Map.merge(default_vocabulary_impls(), user_mapped)
  end

  defp load_vocabularies(builder, map) do
    with {:ok, vocabs} <- do_load_vocabularies(builder, map) do
      {:ok, sort_vocabularies([Vocabulary.Cast | vocabs])}
    end
  end

  defp do_load_vocabularies(builder, map) do
    impls = builder.vocabulary_impls

    EnumExt.reduce_ok(map, [], fn {uri, required?}, acc ->
      case Map.fetch(impls, uri) do
        {:ok, impl} -> {:ok, [impl | acc]}
        :error when required? -> {:error, {:unknown_vocabulary, uri}}
        :error -> {:ok, acc}
      end
    end)
  end

  defp sort_vocabularies(modules) do
    Enum.sort_by(modules, fn
      {module, _} -> module.priority()
      module -> module.priority()
    end)
  end
end
