defmodule JSV.Vocabulary.V202012.Unevaluated do
  alias JSV.Validator
  use JSV.Vocabulary, priority: 900

  def init_validators(_) do
    []
  end

  take_keyword :unevaluatedProperties, unevaluated_properties, acc, builder, _ do
    take_sub(:unevaluatedProperties, unevaluated_properties, acc, builder)
  end

  take_keyword :unevaluatedItems, unevaluated_items, acc, builder, _ do
    take_sub(:unevaluatedItems, unevaluated_items, acc, builder)
  end

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    Map.new(list)
  end

  def validate(data, vds, vctx) do
    Validator.iterate(vds, data, vctx, &validate_keyword/3)
  end

  def validate_keyword({:unevaluatedProperties, subschema}, data, vctx) when is_map(data) do
    evaluated = Validator.list_evaluaded(vctx)

    data
    |> Enum.filter(fn {k, _v} -> k not in evaluated end)
    |> Validator.iterate(data, vctx, fn {k, v}, data, vctx ->
      case Validator.validate_nested(v, k, subschema, vctx) do
        {:ok, _, vctx} -> {:ok, data, vctx}
        {:error, vctx} -> {:error, vctx}
      end
    end)
  end

  pass validate_keyword({:unevaluatedProperties, _})

  def validate_keyword({:unevaluatedItems, subschema}, data, vctx) when is_list(data) do
    evaluated = Validator.list_evaluaded(vctx)

    data
    |> Enum.with_index(0)
    |> Enum.reject(fn {_, index} -> index in evaluated end)
    |> Validator.iterate(data, vctx, fn {item, index}, data, vctx ->
      case Validator.validate_nested(item, index, subschema, vctx) do
        {:ok, _, vctx} -> {:ok, data, vctx}
        {:error, vctx} -> {:error, vctx}
      end
    end)
  end

  pass validate_keyword({:unevaluatedItems, _})

  # ---------------------------------------------------------------------------

  # TODO add tests for error formatting

  def format_error(_, _, _data) do
    "unevaluated value did not conform to schema"
  end
end
