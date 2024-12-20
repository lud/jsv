defmodule JSV.Builder do
  alias JSV.BooleanSchema
  alias JSV.Key
  alias JSV.Ref
  alias JSV.Resolver
  alias JSV.Resolver.Resolved
  alias JSV.RNS
  alias JSV.Root

  @derive {Inspect, except: []}
  @enforce_keys [:resolver]
  defstruct [:resolver, staged: [], vocabularies: nil, ns: nil, parent_ns: nil, opts: []]
  @type t :: %__MODULE__{resolver: term, staged: [term], vocabularies: term, ns: term, parent_ns: term, opts: term}

  def new(opts) do
    {resolver_impl, opts} = Keyword.pop!(opts, :resolver)
    {default_meta, opts} = Keyword.pop!(opts, :default_meta)
    resolver = Resolver.new(resolver_impl, default_meta)
    struct!(__MODULE__, resolver: resolver, opts: opts)
  end

  def build(builder, raw_schema) do
    with {:ok, root_key, resolver} <- Resolver.resolve_root(builder.resolver, raw_schema),
         builder = %__MODULE__{builder | resolver: resolver},
         builder = stage_build(builder, root_key),
         {:ok, validators} <- build_all(builder) do
      {:ok, %Root{raw: raw_schema, validators: validators, root_key: root_key}}
    end
  end

  def stage_build(%{staged: staged} = builder, buildable) do
    %__MODULE__{builder | staged: append_unique(staged, buildable)}
  end

  defp append_unique([key | t], key) do
    append_unique(t, key)
  end

  defp append_unique([h | t], key) do
    [h | append_unique(t, key)]
  end

  defp append_unique([], key) do
    [key]
  end

  def ensure_resolved(%{resolver: resolver} = builder, resolvable) do
    case Resolver.resolve(resolver, resolvable) do
      {:ok, resolver} -> {:ok, %__MODULE__{builder | resolver: resolver}}
      {:error, reason} -> {:error, {:resolver_error, reason}}
    end
  end

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
      {{:resolved, vkey}, %{resolver: resolver} = builder} ->
        with :buildable <- check_not_built(all_validators, vkey),
             {:ok, resolved} <- Resolver.fetch_resolved(resolver, vkey),
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

  defp build_resolved(builder, resolved) do
    %Resolved{meta: meta, ns: ns, parent_ns: parent_ns} = resolved

    case fetch_vocabularies(builder, meta) do
      {:ok, vocabularies} when is_list(vocabularies) ->
        builder = %__MODULE__{builder | vocabularies: vocabularies, ns: ns, parent_ns: parent_ns}
        do_build_sub(resolved.raw, builder)

      {:error, _} = err ->
        err
    end
  end

  defp fetch_vocabularies(builder, meta) do
    case Resolver.fetch_meta(builder.resolver, meta) do
      {:ok, %Resolved{vocabularies: vocabularies}} -> {:ok, vocabularies}
      {:error, _} = err -> err
    end
  end

  def build_sub(%{"$id" => id}, %__MODULE__{} = builder) do
    with {:ok, key} <- RNS.derive(builder.ns, id) do
      {:ok, {:alias_of, key}, stage_build(builder, key)}
    end
  end

  def build_sub(raw_schema, %__MODULE__{} = builder) when is_map(raw_schema) when is_boolean(raw_schema) do
    do_build_sub(raw_schema, builder)
  end

  defp do_build_sub(valid?, %__MODULE__{} = builder) when is_boolean(valid?) do
    {:ok, BooleanSchema.of(valid?), builder}
  end

  defp do_build_sub(raw_schema, %__MODULE__{} = builder) when is_map(raw_schema) do
    {_leftovers, schema_validators, %__MODULE__{} = builder} =
      Enum.reduce(builder.vocabularies, {raw_schema, [], builder}, fn module_or_tuple,
                                                                      {remaining_pairs, schema_validators, builder} ->
        # For one vocabulary module we reduce over the raw schema keywords to
        # accumulate the validator map.
        {module, init_opts} = mod_and_init_opts(module_or_tuple)

        {remaining_pairs, mod_validators, %__MODULE__{} = builder} =
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

    {:ok, %JSV.Subschema{validators: schema_validators}, builder}
  end

  defp mod_and_init_opts({module, opts}) when is_atom(module) and is_list(opts) do
    {module, opts}
  end

  defp mod_and_init_opts(module) when is_atom(module) do
    {module, []}
  end

  defp build_mod_validators(raw_pairs, module, init_opts, builder, raw_schema) when is_map(raw_schema) do
    {leftovers, mod_acc, %__MODULE__{} = builder} =
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

  def vocabulary_enabled?(builder, vocab) do
    Enum.find_value(builder.vocabularies, false, fn
      ^vocab -> true
      {^vocab, _} -> true
      _ -> false
    end)
  end
end
