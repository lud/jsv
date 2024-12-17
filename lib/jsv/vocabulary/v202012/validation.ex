defmodule JSV.Vocabulary.V202012.Validation do
  alias JSV.Helpers
  alias JSV.Validator
  use JSV.Vocabulary, priority: 300

  def init_validators(_) do
    []
  end

  take_keyword :type, t, vds, ctx, _ do
    {:ok, [{:type, valid_type!(t)} | vds], ctx}
  end

  take_keyword :maximum, maximum, acc, ctx, _ do
    take_number(:maximum, maximum, acc, ctx)
  end

  take_keyword :exclusiveMaximum, exclusive_maximum, acc, ctx, _ do
    take_number(:exclusiveMaximum, exclusive_maximum, acc, ctx)
  end

  take_keyword :minimum, minimum, acc, ctx, _ do
    take_number(:minimum, minimum, acc, ctx)
  end

  take_keyword :exclusiveMinimum, exclusive_minimum, acc, ctx, _ do
    take_number(:exclusiveMinimum, exclusive_minimum, acc, ctx)
  end

  take_keyword :minItems, min_items, acc, ctx, _ do
    take_integer(:minItems, min_items, acc, ctx)
  end

  take_keyword :maxItems, max_items, acc, ctx, _ do
    take_integer(:maxItems, max_items, acc, ctx)
  end

  take_keyword :required, required when is_list(required), acc, ctx, _ do
    {:ok, [{:required, required} | acc], ctx}
  end

  take_keyword :multipleOf, zero when zero in [0, 0.0], _acc, _ctx, _ do
    {:error, "mutipleOf zero is not allowed"}
  end

  take_keyword :multipleOf, multiple_of, acc, ctx, _ do
    take_number(:multipleOf, multiple_of, acc, ctx)
  end

  take_keyword :const, const, acc, ctx, _ do
    {:ok, [{:const, const} | acc], ctx}
  end

  take_keyword :maxLength, max_length, acc, ctx, _ do
    take_integer(:maxLength, max_length, acc, ctx)
  end

  take_keyword :minLength, min_length, acc, ctx, _ do
    take_integer(:minLength, min_length, acc, ctx)
  end

  take_keyword :minProperties, min_properties, acc, ctx, _ do
    take_integer(:minProperties, min_properties, acc, ctx)
  end

  take_keyword :maxProperties, max_properties, acc, ctx, _ do
    take_integer(:maxProperties, max_properties, acc, ctx)
  end

  take_keyword :enum, enum, acc, ctx, _ do
    {:ok, [{:enum, enum} | acc], ctx}
  end

  take_keyword :pattern, pattern, acc, ctx, _ do
    case Regex.compile(pattern) do
      {:ok, re} -> {:ok, [{:pattern, re} | acc], ctx}
      {:error, _} -> {:error, {:invalid_pattern, pattern}}
    end
  end

  take_keyword :uniqueItems, unique?, acc, ctx, _ do
    if unique? do
      {:ok, [{:uniqueItems, true} | acc], ctx}
    else
      {:ok, acc, ctx}
    end
  end

  take_keyword :dependentRequired, dependent_required, acc, ctx, _ do
    {:ok, [{:dependentRequired, dependent_required} | acc], ctx}
  end

  # minContains/maxContains is handled by the Applicator module IF the validation vocabulary is
  # enabled
  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    list
  end

  # -----------------------------------------------------------------------------

  defp valid_type!(list) when is_list(list) do
    Enum.map(list, &valid_type!/1)
  end

  defp valid_type!("array") do
    :array
  end

  defp valid_type!("object") do
    :object
  end

  defp valid_type!("null") do
    :null
  end

  defp valid_type!("boolean") do
    :boolean
  end

  defp valid_type!("string") do
    :string
  end

  defp valid_type!("integer") do
    :integer
  end

  defp valid_type!("number") do
    :number
  end

  def validate(data, vds, vdr) do
    Validator.iterate(vds, data, vdr, &validate_keyword/3)
  end

  def validate_keyword({:type, ts}, data, vdr) when is_list(ts) do
    Enum.find_value(ts, fn t ->
      case validate_type(data, t) do
        true -> {:ok, data}
        false -> nil
        {:swap, new_data} -> {:ok, new_data}
      end
    end)
    |> case do
      {:ok, data} -> {:ok, data, vdr}
      nil -> {:error, Validator.with_error(vdr, :type, data, type: ts)}
    end
  end

  def validate_keyword({:type, t}, data, vdr) do
    case validate_type(data, t) do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :type, data, type: t)}
      {:swap, new_data} -> {:ok, new_data, vdr}
    end
  end

  def validate_keyword({:maximum, n}, data, vdr) when is_number(data) do
    case data <= n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :maximum, data, n: n)}
    end
  end

  pass validate_keyword({:maximum, _})

  def validate_keyword({:exclusiveMaximum, n}, data, vdr) when is_number(data) do
    case data < n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :exclusiveMaximum, data, n: n)}
    end
  end

  pass validate_keyword({:exclusiveMaximum, _})

  def validate_keyword({:minimum, n}, data, vdr) when is_number(data) do
    case data >= n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :minimum, data, n: n)}
    end
  end

  pass validate_keyword({:minimum, _})

  def validate_keyword({:exclusiveMinimum, n}, data, vdr) when is_number(data) do
    case data > n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :exclusiveMinimum, data, n: n)}
    end
  end

  pass validate_keyword({:exclusiveMinimum, _})

  def validate_keyword({:maxItems, max}, data, vdr) when is_list(data) do
    len = length(data)

    if len <= max do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :maxItems, data, max_items: max, len: len)}
    end
  end

  pass validate_keyword({:maxItems, _})

  def validate_keyword({:minItems, min}, data, vdr) when is_list(data) do
    len = length(data)

    if len >= min do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :minItems, data, min_items: min, len: len)}
    end
  end

  pass validate_keyword({:minItems, _})

  def validate_keyword({:multipleOf, n}, data, vdr) when is_number(data) do
    case Helpers.fractional_is_zero?(data / n) do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :multipleOf, data, multiple_of: n)}
    end
  rescue
    # Rescue infinite division (huge numbers divided by float, too large invalid
    # floats)
    _ in ArithmeticError -> {:error, Validator.with_error(vdr, :arithmetic_error, data, context: "multipleOf")}
  end

  pass validate_keyword({:multipleOf, _})

  def validate_keyword({:required, required_keys}, data, vdr) when is_map(data) do
    case required_keys -- Map.keys(data) do
      [] -> {:ok, data, vdr}
      missing -> {:error, Validator.with_error(vdr, :required, data, required: missing)}
    end
  end

  pass validate_keyword({:required, _})

  def validate_keyword({:dependentRequired, dependent_required}, data, vdr) do
    validate_dependent_required(dependent_required, data, vdr)
  end

  def validate_keyword({:maxLength, max}, data, vdr) when is_binary(data) do
    len = String.length(data)

    if len <= max do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :maxLength, data, max_length: max, len: len)}
    end
  end

  pass validate_keyword({:maxLength, _})

  def validate_keyword({:minLength, min}, data, vdr) when is_binary(data) do
    len = String.length(data)

    if len >= min do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :minLength, data, min_length: min, len: len)}
    end
  end

  pass validate_keyword({:minLength, _})

  def validate_keyword({:const, const}, data, vdr) do
    # 1 == 1.0 should be true according to JSON Schema specs
    if data == const do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :const, data, const: const)}
    end
  end

  def validate_keyword({:enum, enum}, data, vdr) do
    # validate 1 == 1.0 or 1.0 == 1
    if Enum.any?(enum, &(&1 == data)) do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :enum, data, enum: enum)}
    end
  end

  def validate_keyword({:pattern, re}, data, vdr) when is_binary(data) do
    if Regex.match?(re, data) do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :pattern, data, pattern: re.source)}
    end
  end

  pass validate_keyword({:pattern, _})

  def validate_keyword({:uniqueItems, true}, data, vdr) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn {item, index}, {duplicate_indices, seen} ->
      case Map.fetch(seen, item) do
        {:ok, seen_index} -> {[{index, seen_index} | duplicate_indices], seen}
        :error -> {duplicate_indices, Map.put(seen, item, index)}
      end
    end)
    |> case do
      {[], _} -> {:ok, data, vdr}
      {duplicates, _} -> {:error, Validator.with_error(vdr, :uniqueItems, data, duplicates: Map.new(duplicates))}
    end
  end

  pass validate_keyword({:uniqueItems, true})

  def validate_keyword({:minProperties, n}, data, vdr) when is_map(data) do
    case map_size(data) do
      size when size < n -> {:error, Validator.with_error(vdr, :minProperties, data, min_properties: n, size: size)}
      _ -> {:ok, data, vdr}
    end
  end

  pass validate_keyword({:minProperties, _})

  def validate_keyword({:maxProperties, n}, data, vdr) when is_map(data) do
    case map_size(data) do
      size when size > n -> {:error, Validator.with_error(vdr, :maxProperties, data, max_properties: n, size: size)}
      _ -> {:ok, data, vdr}
    end
  end

  pass validate_keyword({:maxProperties, _})

  # ---------------------------------------------------------------------------

  # Shared to support "dependencies" compatibility
  @doc false
  def validate_dependent_required(dependent_required, data, vdr) when is_map(data) do
    all_keys = Map.keys(data)

    Validator.iterate(dependent_required, data, vdr, fn
      {parent_key, required_keys}, data, vdr when is_map_key(data, parent_key) ->
        case required_keys -- all_keys do
          [] ->
            {:ok, data, vdr}

          missing ->
            {:error, Validator.with_error(vdr, :dependentRequired, data, parent: parent_key, missing: missing)}
        end

      {_, _}, data, vdr ->
        {:ok, data, vdr}
    end)
  end

  def validate_dependent_required(_dependent_required, data, vdr) do
    {:ok, data, vdr}
  end

  defp validate_type(data, :array) do
    is_list(data)
  end

  defp validate_type(data, :object) do
    is_map(data)
  end

  defp validate_type(data, :null) do
    data === nil
  end

  defp validate_type(data, :boolean) do
    is_boolean(data)
  end

  defp validate_type(data, :string) do
    is_binary(data)
  end

  defp validate_type(data, :integer) when is_float(data) do
    Helpers.fractional_is_zero?(data) && {:swap, trunc(data)}
  end

  defp validate_type(data, :integer) do
    is_integer(data)
  end

  defp validate_type(data, :number) do
    is_number(data)
  end

  # ---------------------------------------------------------------------------

  def format_error(:type, args, _) do
    %{type: type} = args
    types_format = type |> List.wrap() |> Enum.map_intersperse(" or ", &Atom.to_string/1)
    "value is not of type #{types_format}"
  end

  def format_error(:minimum, %{n: n}, data) do
    "value #{data} is lower than minimum #{n}"
  end

  def format_error(:exclusiveMinimum, %{n: n}, data) do
    "value #{data} is not higher than exclusive minimum #{n}"
  end

  def format_error(:maximum, %{n: n}, data) do
    "value #{data} is higher than maximum #{n}"
  end

  def format_error(:exclusiveMaximum, %{n: n}, data) do
    "value #{data} is not lower than exclusive maximum #{n}"
  end

  def format_error(:minLength, %{len: len, min_length: min_length}, _data) do
    "value length must be at least #{min_length} but is #{len}"
  end

  def format_error(:maxLength, %{len: len, max_length: max_length}, _data) do
    "value length must be at most #{max_length} but is #{len}"
  end

  def format_error(:const, %{const: const}, _data) do
    "value should be #{Jason.encode!(const)}"
  end

  def format_error(:required, %{required: required}, _data) do
    case required do
      [single] -> "property #{quote_prop(single)} is required"
      _ -> "properties #{required |> Enum.map(&quote_prop/1) |> verbose_list("and")} are required"
    end
  end

  def format_error(:multipleOf, %{multiple_of: multiple_of}, data) do
    "value #{data} is not a multiple of #{multiple_of}"
  end

  def format_error(:pattern, %{pattern: pattern}, _data) do
    "value does not conform to pattern /#{pattern}/"
  end

  def format_error(:maxItems, %{len: len, max_items: max_items}, _data) do
    "value should have at most #{max_items} items, got #{len}"
  end

  def format_error(:minItems, %{len: len, min_items: min_items}, _data) do
    "value should have at least #{min_items} items, got #{len}"
  end

  def format_error(:minProperties, %{size: size, min_properties: min_properties}, _data) do
    "value must have at least #{min_properties} properties, got #{size}"
  end

  def format_error(:maxProperties, %{size: size, max_properties: max_properties}, _data) do
    "value must have at most #{max_properties} properties, got #{size}"
  end

  def format_error(:enum, %{enum: enum}, _data) do
    "value must be one of the enum values: #{enum |> Enum.map(&inspect/1) |> verbose_list("or")}"
  end

  def format_error(:dependentRequired, %{parent: parent, missing: missing}, _data) do
    case missing do
      [single] ->
        "property #{quote_prop(single)} is required when property #{quote_prop(parent)} is present"

      _ ->
        "properties #{missing |> Enum.map(&quote_prop/1) |> verbose_list("and")} are required when property #{quote_prop(parent)} is present"
    end
  end

  def format_error(:uniqueItems, %{duplicates: duplicates}, _data) do
    printout =
      Enum.map(duplicates, fn {dup_index, seen_index} ->
        "values at indices #{seen_index} and #{dup_index} are equal"
      end)

    "value must contain unique items but #{verbose_list(printout, "and")}"
  end

  def format_error(:arithmetic_error, %{context: context}, data) do
    "could not valiade #{inspect(data)}, got arithmetic error in context #{quote_prop(context)}"
  end

  defp verbose_list([single], _) do
    single
  end

  defp verbose_list([_ | _] = list, operator) do
    [last | [_ | _] = rest] = :lists.reverse(list)
    rest = :lists.reverse(rest)
    [Enum.intersperse(rest, ", "), " ", operator, " ", last]
  end

  defp quote_prop(val) do
    ["'", val, "'"]
  end
end
