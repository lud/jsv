defmodule JSV.Vocabulary.V202012.Unevaluated do
  alias JSV.Validator
  use JSV.Vocabulary, priority: 900

  @impl true
  def init_validators(_) do
    []
  end

  @impl true

  def take_keyword({"unevaluatedProperties", unevaluated_properties}, acc, ctx, _) do
    take_sub(:unevaluated_properties, unevaluated_properties, acc, ctx)
  end

  def take_keyword({"unevaluatedItems", unevaluated_items}, acc, ctx, _) do
    take_sub(:unevaluated_items, unevaluated_items, acc, ctx)
  end

  ignore_any_keyword()

  @impl true
  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    Map.new(list)
  end

  @impl true
  def validate(data, vds, vdr) do
    Validator.iterate(vds, data, vdr, &validate_keyword/3)
  end

  def validate_keyword({:unevaluated_properties, subschema}, data, vdr) when is_map(data) do
    evaluated = Validator.list_evaluaded(vdr)

    data
    |> Enum.filter(fn {k, _v} -> k not in evaluated end)
    |> Validator.iterate(data, vdr, fn {k, v}, data, vdr ->
      case Validator.validate_nested(v, k, subschema, vdr) do
        {:ok, _, vdr} -> {:ok, data, vdr}
        {:error, vdr} -> {:error, vdr}
      end
    end)
  end

  pass validate_keyword({:unevaluated_properties, _})

  def validate_keyword({:unevaluated_items, subschema}, data, vdr) when is_list(data) do
    evaluated = Validator.list_evaluaded(vdr)

    data
    |> Enum.with_index(0)
    |> Enum.reject(fn {_, index} -> index in evaluated end)
    |> Validator.iterate(data, vdr, fn {item, index}, data, vdr ->
      case Validator.validate_nested(item, index, subschema, vdr) do
        {:ok, _, vdr} -> {:ok, data, vdr}
        {:error, vdr} -> {:error, vdr}
      end
    end)
  end

  pass validate_keyword({:unevaluated_items, _})

  # ---------------------------------------------------------------------------

  # TODO add tests for error formatting

  @impl true
  def format_error(_, _, _data) do
    "unevaluated value did not conform to schema"
  end
end
