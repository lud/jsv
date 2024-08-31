defmodule Moonwalk.Schema.Vocabulary.Draft7.Applicator do
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Vocabulary.V202012.Applicator, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 200

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true
  defdelegate format_error(key, args, data), to: Fallback

  @impl true
  def take_keyword({"additionalItems", items}, acc, ctx, _) do
    take_sub(:additional_items, items, acc, ctx)
  end

  def take_keyword({"items", items}, acc, ctx, _) when is_map(items) do
    take_sub(:items, items, acc, ctx)
  end

  def take_keyword({"items", items}, acc, ctx, _) when is_list(items) do
    items
    |> Helpers.reduce_ok({[], ctx}, fn item, {subacc, ctx} ->
      case Builder.build_sub(item, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {[subvalidators | subacc], ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:items, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword(pair, acc, ctx, raw_schema) do
    Fallback.take_keyword(pair, acc, ctx, raw_schema)
  end

  @impl true
  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(validators) do
    validators = finalize_items(validators)

    Fallback.finalize_validators(validators)
  end

  defp finalize_items(validators) do
    {items, validators} = Keyword.pop(validators, :items, nil)
    {additional_items, validators} = Keyword.pop(validators, :additional_items, nil)

    case {items, additional_items} do
      {nil, nil} -> validators
      {item_map, _} when is_map(item_map) -> Keyword.put(validators, :all_items, {item_map, nil})
      some -> Keyword.put(validators, :all_items, some)
    end
  end

  @impl true
  def validate(data, vds, vdr) do
    Validator.iterate(vds, data, vdr, &validate_keyword/3)
  end

  def validate_keyword({:all_items, {items, additional_items}}, data, vdr) when is_list(items) and is_list(data) do
    all_schemas = Stream.concat(List.wrap(items), Stream.cycle([additional_items]))

    index_items = Stream.with_index(data)

    zipped = Enum.zip(index_items, all_schemas)

    {rev_items, vdr} =
      Enum.reduce(zipped, {[], vdr}, fn
        {{item, _index}, nil}, {casted, vdr} ->
          # TODO add evaluated path to validator
          {[item | casted], vdr}

        {{item, index}, subschema}, {casted, vdr} ->
          case Validator.validate_nested(item, index, subschema, vdr) do
            {:ok, casted_item, vdr} -> {[casted_item | casted], vdr}
            {:error, vdr} -> {[item | casted], Validator.with_error(vdr, :item, item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vdr)
  end

  def validate_keyword({:all_items, {items, _}}, data, vdr) when is_map(items) and is_list(data) do
    all_schemas = Stream.cycle([items])

    index_items = Stream.with_index(data)

    zipped = Enum.zip(index_items, all_schemas)

    {rev_items, vdr} =
      Enum.reduce(zipped, {[], vdr}, fn
        {{item, _index}, nil}, {casted, vdr} ->
          # TODO add evaluated path to validator
          {[item | casted], vdr}

        {{item, index}, subschema}, {casted, vdr} ->
          case Validator.validate_nested(item, index, subschema, vdr) do
            {:ok, casted_item, vdr} -> {[casted_item | casted], vdr}
            {:error, vdr} -> {[item | casted], Validator.with_error(vdr, :item, item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vdr)
  end

  pass validate_keyword({:all_items, _})

  def validate_keyword(vd, data, vdr) do
    Fallback.validate_keyword(vd, data, vdr)
  end
end
