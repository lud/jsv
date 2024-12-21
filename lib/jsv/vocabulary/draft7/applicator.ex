defmodule JSV.Vocabulary.Draft7.Applicator do
  alias JSV.Builder
  alias JSV.Helpers
  alias JSV.Validator
  alias JSV.Vocabulary.V202012.Applicator, as: Fallback
  use JSV.Vocabulary, priority: 200

  defdelegate init_validators(opts), to: Fallback

  take_keyword :additionalItems, items, acc, builder, _ do
    take_sub(:additionalItems, items, acc, builder)
  end

  take_keyword :items, items when is_map(items), acc, builder, _ do
    take_sub(:items, items, acc, builder)
  end

  take_keyword :items, items when is_list(items), acc, builder, _ do
    items
    |> Helpers.reduce_ok({[], builder}, fn item, {subacc, builder} ->
      case Builder.build_sub(item, builder) do
        {:ok, subvalidators, builder} -> {:ok, {[subvalidators | subacc], builder}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, builder}} -> {:ok, [{:items, :lists.reverse(subvalidators)} | acc], builder}
      {:error, _} = err -> err
    end
  end

  def handle_keyword(pair, acc, builder, raw_schema) do
    Fallback.handle_keyword(pair, acc, builder, raw_schema)
  end

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(validators) do
    validators = finalize_items(validators)

    Fallback.finalize_validators(validators)
  end

  defp finalize_items(validators) do
    {items, validators} = Keyword.pop(validators, :items, nil)
    {additional_items, validators} = Keyword.pop(validators, :additionalItems, nil)

    case {items, additional_items} do
      {nil, nil} -> validators
      {item_map, _} when is_map(item_map) -> Keyword.put(validators, :items@jsv, {item_map, nil})
      some -> Keyword.put(validators, :items@jsv, some)
    end
  end

  def validate(data, vds, vctx) do
    Validator.iterate(vds, data, vctx, &validate_keyword/3)
  end

  # draft-7 supports items as a map or an array (which was replaced by prefix
  # items). This clause is for array.
  def validate_keyword({:items@jsv, {items_schemas, additional_items_schema}}, data, vctx)
      when is_list(items_schemas) and (is_map(additional_items_schema) or is_nil(additional_items_schema)) and
             is_list(data) do
    prefix_stream = Enum.map(items_schemas, &{:items_as_prefix, &1})

    rest_stream = Stream.cycle([{:additionalItems, additional_items_schema}])
    all_stream = Stream.concat(prefix_stream, rest_stream)
    data_items_index = Stream.with_index(data)

    # Zipping items with their schemas. If the schema only specifies
    # prefixItems, then items_schema is nil and the zip will associate with nil.
    zipped =
      Enum.zip_with([data_items_index, all_stream], fn
        [{data_item, index}, {kind, schema}] -> {kind, data_item, index, schema}
      end)

    {rev_items, vctx} =
      Enum.reduce(zipped, {[], vctx}, fn
        {_kind, data_item, _index, nil = _subschema}, {casted, vctx} ->
          # TODO add evaluated path to validator
          {[data_item | casted], vctx}

        {kind, data_item, index, subschema}, {casted, vctx} ->
          eval_path = eval_path(kind, index)

          case Validator.validate_nested(data_item, index, eval_path, subschema, vctx) do
            {:ok, casted_item, vctx} -> {[casted_item | casted], vctx}
            {:error, vctx} -> {[data_item | casted], Validator.with_error(vctx, kind, data_item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vctx)
  end

  IO.warn("todo refactor items clause, we can reuse the same mapper function")

  # Items is a map, we will not use additional items.
  def validate_keyword({:items@jsv, {items_schema, _}}, data, vctx)
      when (is_map(items_schema) or (is_tuple(items_schema) and elem(items_schema, 0) == :alias_of)) and
             is_list(data) do
    all_stream = Stream.cycle([{:items, items_schema}])
    data_items_index = Enum.with_index(data)

    zipped =
      Enum.zip_with([data_items_index, all_stream], fn
        [{data_item, index}, {kind, schema}] -> {kind, data_item, index, schema}
      end)

    {rev_items, vctx} =
      Enum.reduce(zipped, {[], vctx}, fn
        {kind, data_item, index, subschema}, {casted, vctx} ->
          eval_path = eval_path(kind, index)

          case Validator.validate_nested(data_item, index, eval_path, subschema, vctx) do
            {:ok, casted_item, vctx} -> {[casted_item | casted], vctx}
            {:error, vctx} -> {[data_item | casted], Validator.with_error(vctx, :items, data_item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vctx)
  end

  # this also passes when items schema is nil. In that case the additionalItems
  # schema is not used, every item is valid.
  pass validate_keyword({:items@jsv, _})

  def validate_keyword(vd, data, vctx) do
    Fallback.validate_keyword(vd, data, vctx)
  end

  defp eval_path(kind, arg) do
    case kind do
      # :property -> [:properties, arg]
      # :additional -> :additionalProperties
      # :pattern -> [:patternProperties, arg]
      # in draf-7 a prefix item is the "items" keyword with an array of schemas
      :items -> :items
      :items_as_prefix -> [:items, arg]
      :additionalItems -> :additionalItems
    end
  end

  def format_error(:additionalItems, args, _) do
    %{index: index} = args
    "item at index #{index} does not validate the 'additionalItems' schema"
  end

  def format_error(:items_as_prefix, args, _) do
    %{index: index} = args
    "item at index #{index} does not validate the 'items[#{index}]' schema"
  end

  defdelegate format_error(key, args, data), to: Fallback
end
