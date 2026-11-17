defmodule JSV.Vocabulary.V7.Applicator do
  alias JSV.Builder
  alias JSV.Validator
  alias JSV.Vocabulary.V202012.Applicator, as: Fallback
  use JSV.Vocabulary, priority: 200

  @moduledoc """
  Implementation of the applicator vocabulary with draft 7 sepecifiticies.
  """

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true
  take_keyword :additionalItems, items, acc, builder, _ do
    take_sub_with_formatter(:additionalItems, :additionalItems, items, acc, builder)
  end

  take_keyword :items, items when is_map(items), acc, builder, _ do
    take_sub_with_formatter(:items, :items, items, acc, builder)
  end

  take_keyword :items, items when is_list(items), acc, builder, _ do
    {subvalidators, builder} =
      Fallback.build_sub_list(:items_as_prefix, items, builder,
        error_formatter: {__MODULE__, keyword: :items_as_prefix}
      )

    {[{:items, subvalidators} | acc], builder}
  end

  def handle_keyword(pair, acc, builder, raw_schema) do
    Fallback.handle_keyword(pair, acc, builder, raw_schema)
  end

  defp take_sub_with_formatter(key, formatter_keyword, raw_schema, acc, builder) do
    {subvalidators, builder} =
      Builder.build_sub!(raw_schema, [key], builder, error_formatter: {__MODULE__, keyword: formatter_keyword})

    {[{key, subvalidators} | acc], builder}
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
    {additional_items, validators} = Keyword.pop(validators, :additionalItems, nil)

    case {items, additional_items} do
      {nil, nil} -> validators
      {item_map, _} when is_map(item_map) -> Keyword.put(validators, :jsv@array, {item_map, nil})
      some -> Keyword.put(validators, :jsv@array, some)
    end
  end

  @impl true
  def validate(data, vds, vctx) do
    Validator.reduce(vds, data, vctx, &validate_keyword/3)
  end

  # draft-7 supports items as a map or an array (which was replaced by prefix
  # items). This clause is for array.
  defp validate_keyword({:jsv@array, {items_schemas, additional_items_schema}}, data, vctx)
       when is_list(items_schemas) and (is_map(additional_items_schema) or is_nil(additional_items_schema)) and
              is_list(data) do
    zipped = Fallback.zip_items(data, items_schemas, :items_as_prefix, additional_items_schema, :additionalItems)
    {validated_items, vctx} = Fallback.validate_items(zipped, vctx, __MODULE__)
    Validator.return(validated_items, vctx)
  end

  # Items is a map, we will not use additional items.
  defp validate_keyword({:jsv@array, {items_schema, _}}, data, vctx)
       when (is_map(items_schema) or (is_tuple(items_schema) and elem(items_schema, 0) == :alias_of)) and
              is_list(data) do
    zipped = Fallback.zip_items(data, [], :items, items_schema, :items)
    {validated_items, vctx} = Fallback.validate_items(zipped, vctx, __MODULE__)
    Validator.return(validated_items, vctx)
  end

  # this also passes when items schema is nil. In that case the additionalItems
  # schema is not used, every item is valid.
  passp validate_keyword({:jsv@array, _})

  defp validate_keyword(vd, data, vctx) do
    Fallback.validate_keyword(vd, data, vctx)
  end

  @impl true
  def format_error(:additionalItems, %{index: index}, _) do
    "item at index #{index} does not validate the 'additionalItems' schema"
  end

  def format_error(:items_as_prefix, %{index: index}, _) do
    "item at index #{index} does not validate the 'items[#{index}]' schema"
  end

  def format_error(:boolean_schema, %{keyword: :additionalItems, key: index}, _data) do
    "additional items are not allowed but found item at index #{index}"
  end

  def format_error(:boolean_schema, %{keyword: :items_as_prefix, key: index}, _data) do
    "item at index #{index} is not allowed"
  end

  defdelegate format_error(key, args, data), to: Fallback
end
