defmodule JSV.Vocabulary.Draft7.Applicator do
  alias JSV.Builder
  alias JSV.Helpers
  alias JSV.Validator
  alias JSV.Vocabulary.V202012.Applicator, as: Fallback
  use JSV.Vocabulary, priority: 200

  defdelegate init_validators(opts), to: Fallback

  defdelegate format_error(key, args, data), to: Fallback

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

  def validate_keyword({:items@jsv, {items, additional_items}}, data, vctx) when is_list(items) and is_list(data) do
    all_schemas = Stream.concat(List.wrap(items), Stream.cycle([additional_items]))

    index_items = Stream.with_index(data)

    zipped = Enum.zip(index_items, all_schemas)

    {rev_items, vctx} =
      Enum.reduce(zipped, {[], vctx}, fn
        {{item, _index}, nil}, {casted, vctx} ->
          # TODO add evaluated path to validator
          {[item | casted], vctx}

        {{item, index}, subschema}, {casted, vctx} ->
          case Validator.validate_nested(item, index, subschema, vctx) do
            {:ok, casted_item, vctx} -> {[casted_item | casted], vctx}
            {:error, vctx} -> {[item | casted], Validator.with_error(vctx, :item, item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vctx)
  end

  def validate_keyword({:items@jsv, {items, _}}, data, vctx)
      when (is_map(items) or (is_tuple(items) and elem(items, 0) == :alias_of)) and is_list(data) do
    all_schemas = Stream.cycle([items])

    index_items = Stream.with_index(data)

    zipped = Enum.zip(index_items, all_schemas)

    {rev_items, vctx} =
      Enum.reduce(zipped, {[], vctx}, fn
        {{item, _index}, nil}, {casted, vctx} ->
          # TODO add evaluated path to validator
          {[item | casted], vctx}

        {{item, index}, subschema}, {casted, vctx} ->
          case Validator.validate_nested(item, index, subschema, vctx) do
            {:ok, casted_item, vctx} -> {[casted_item | casted], vctx}
            {:error, vctx} -> {[item | casted], Validator.with_error(vctx, :item, item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vctx)
  end

  pass validate_keyword({:items@jsv, _})

  def validate_keyword(vd, data, vctx) do
    Fallback.validate_keyword(vd, data, vctx)
  end
end
