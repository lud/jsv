defmodule JSV.Vocabulary.V202012.Applicator do
  alias JSV.Builder
  alias JSV.Helpers
  alias JSV.Validator
  alias JSV.Vocabulary.V202012.Validation
  use JSV.Vocabulary, priority: 200

  def init_validators(_) do
    []
  end

  take_keyword :properties, properties, acc, ctx, _ do
    properties
    |> Helpers.reduce_ok({%{}, ctx}, fn {k, pschema}, {acc, ctx} ->
      case Builder.build_sub(pschema, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {Map.put(acc, k, subvalidators), ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:properties, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :additionalProperties, additional_properties, acc, ctx, _ do
    take_sub(:additionalProperties, additional_properties, acc, ctx)
  end

  take_keyword :patternProperties, pattern_properties, acc, ctx, _ do
    pattern_properties
    |> Helpers.reduce_ok({%{}, ctx}, fn {k, pschema}, {acc, ctx} ->
      with {:ok, re} <- Regex.compile(k),
           {:ok, subvalidators, ctx} <- Builder.build_sub(pschema, ctx) do
        {:ok, {Map.put(acc, {k, re}, subvalidators), ctx}}
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:patternProperties, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :items, items, acc, ctx, _ do
    take_sub(:items, items, acc, ctx)
  end

  take_keyword :prefixItems, prefix_items, acc, ctx, _ do
    prefix_items
    |> Helpers.reduce_ok({[], ctx}, fn item, {subacc, ctx} ->
      case Builder.build_sub(item, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {[subvalidators | subacc], ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:prefixItems, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :allOf, [_ | _] = all_of, acc, ctx, _ do
    case build_sub_list(all_of, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:allOf, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :anyOf, [_ | _] = any_of, acc, ctx, _ do
    case build_sub_list(any_of, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:anyOf, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :oneOf, [_ | _] = one_of, acc, ctx, _ do
    case build_sub_list(one_of, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:oneOf, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :if, if_schema, acc, ctx, _ do
    take_sub(:if, if_schema, acc, ctx)
  end

  take_keyword :then, then, acc, ctx, _ do
    take_sub(:then, then, acc, ctx)
  end

  take_keyword :else, else_schema, acc, ctx, _ do
    take_sub(:else, else_schema, acc, ctx)
  end

  take_keyword :propertyNames, property_names, acc, ctx, _ do
    take_sub(:propertyNames, property_names, acc, ctx)
  end

  take_keyword :contains, contains, acc, ctx, _ do
    take_sub(:contains, contains, acc, ctx)
  end

  take_keyword :maxContains, max_contains, acc, ctx, _ do
    if validation_enabled?(ctx) do
      take_integer(:maxContains, max_contains, acc, ctx)
    else
      :ignore
    end
  end

  take_keyword :minContains, min_contains, acc, ctx, _ do
    if validation_enabled?(ctx) do
      take_integer(:minContains, min_contains, acc, ctx)
    else
      :ignore
    end
  end

  take_keyword :dependentSchemas, dependent_schemas, acc, ctx, _ do
    dependent_schemas
    |> Helpers.reduce_ok({%{}, ctx}, fn {k, depschema}, {acc, ctx} ->
      case Builder.build_sub(depschema, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {Map.put(acc, k, subvalidators), ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:dependentSchemas, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  take_keyword :dependencies, map when is_map(map), acc, ctx, raw_schema do
    {dependent_schemas, dependent_required} =
      Enum.reduce(map, {[], []}, fn {key, subschema}, {dependent_schemas, dependent_required} ->
        cond do
          is_list(subschema) && Enum.all?(subschema, &is_binary/1) ->
            {dependent_schemas, [{key, subschema} | dependent_required]}

          is_boolean(subschema) || is_map(subschema) ->
            {[{key, subschema} | dependent_schemas], dependent_required}
        end
      end)

    with {:ok, acc, ctx} <- handle_keyword({:dependentSchemas, dependent_schemas}, acc, ctx, raw_schema) do
      {:ok, [{:dependentRequired, dependent_required} | acc], ctx}
    end
  end

  take_keyword :not, subschema, acc, ctx, _ do
    take_sub(:not, subschema, acc, ctx)
  end

  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  defp build_sub_list(subschemas, ctx) do
    Helpers.reduce_ok(subschemas, {[], ctx}, fn subschema, {acc, ctx} ->
      case Builder.build_sub(subschema, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {[subvalidators | acc], ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, :lists.reverse(subvalidators), ctx}
      {:error, _} = err -> err
    end
  end

  # ---------------------------------------------------------------------------

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(validators) do
    validators = finalize_properties(validators)
    validators = finalize_if_then_else(validators)
    validators = finalize_items(validators)
    validators = finalize_contains(validators)
    validators
  end

  defp finalize_properties(validators) do
    {properties, validators} = Keyword.pop(validators, :properties, nil)
    {pattern_properties, validators} = Keyword.pop(validators, :patternProperties, nil)
    {additional_properties, validators} = Keyword.pop(validators, :additionalProperties, nil)

    case {properties, pattern_properties, additional_properties} do
      {nil, nil, nil} ->
        validators

      _ ->
        Keyword.put(validators, :properties@jsv, {properties, pattern_properties, additional_properties})
    end
  end

  defp finalize_items(validators) do
    {items, validators} = Keyword.pop(validators, :items, nil)
    {prefix_items, validators} = Keyword.pop(validators, :prefixItems, nil)

    case {items, prefix_items} do
      {nil, nil} -> validators
      some -> Keyword.put(validators, :items@jsv, some)
    end
  end

  defp finalize_if_then_else(validators) do
    {if_vds, validators} = Keyword.pop(validators, :if, nil)
    {then_vds, validators} = Keyword.pop(validators, :then, nil)
    {else_vds, validators} = Keyword.pop(validators, :else, nil)

    case {if_vds, then_vds, else_vds} do
      {nil, _, _} -> validators
      some -> Keyword.put(validators, :if@jsv, some)
    end
  end

  defp finalize_contains(validators) do
    {contains, validators} = Keyword.pop(validators, :contains, nil)
    {min_contains, validators} = Keyword.pop(validators, :minContains, 1)
    {max_contains, validators} = Keyword.pop(validators, :maxContains, nil)

    case {contains, min_contains, max_contains} do
      {nil, _, _} -> validators
      some -> Keyword.put(validators, :contains@jsv, some)
    end
  end

  # ---------------------------------------------------------------------------

  def validate(data, vds, vdr) do
    Validator.iterate(vds, data, vdr, &validate_keyword/3)
  end

  defp property_validations(_data, nil) do
    []
  end

  defp property_validations(data, properties) do
    Enum.flat_map(properties, fn
      {key, subschema} when is_map_key(data, key) -> [{:property, key, subschema, nil}]
      _ -> []
    end)
  end

  defp pattern_validations(_data, nil) do
    []
  end

  defp pattern_validations(data, pattern_properties) do
    for {{pattern, re}, subschema} <- pattern_properties,
        {key, _} <- data,
        Regex.match?(re, key) do
      {:pattern, key, subschema, pattern}
    end
  end

  def validate_keyword({:properties@jsv, {properties, pattern_properties, additional_properties}}, data, vdr)
      when is_map(data) do
    for_props = property_validations(data, properties)
    for_patterns = pattern_validations(data, pattern_properties)

    validations = for_props ++ for_patterns

    for_additional =
      case additional_properties do
        nil ->
          []

        _ ->
          Enum.flat_map(data, fn {key, _} ->
            if List.keymember?(validations, key, 1) do
              []
            else
              [{:additional, key, additional_properties, nil}]
            end
          end)
      end

    all_validations = for_additional ++ validations

    # Note: if a property is validated by both :properties and
    # :patternProperties, casted data from the first schema is evaluted by the
    # second. A possible fix is to discard previously casted value on second
    # schema but we will loose all cast from nested schemas.

    Validator.iterate(all_validations, data, vdr, fn
      {_kind, key, subschema, _pattern} = propcase, data, vdr ->
        case Validator.validate_nested(Map.fetch!(data, key), key, subschema, vdr) do
          {:ok, casted, vdr} -> {:ok, Map.put(data, key, casted), vdr}
          {:error, vdr} -> {:error, with_property_error(vdr, data, propcase)}
        end
    end)
  end

  pass validate_keyword({:properties@jsv, _})

  def validate_keyword({:items@jsv, {items, prefix_items}}, data, vdr) when is_list(data) do
    all_schemas = Stream.concat(List.wrap(prefix_items), Stream.cycle([items]))

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

  pass validate_keyword({:items@jsv, _})

  def validate_keyword({:oneOf, subvalidators}, data, vdr) do
    case validate_split(subvalidators, data, vdr) do
      {[{_, data}], _, vdr} ->
        {:ok, data, vdr}

      {[], _, _} ->
        # TODO compute branch error of all invalid
        {:error, Validator.with_error(vdr, :oneOf, data, validated_schemas: [])}

      {[_ | _] = too_much, _, _} ->
        validated_schemas = Enum.map(too_much, &elem(&1, 0))
        {:error, Validator.with_error(vdr, :oneOf, data, validated_schemas: validated_schemas)}
    end
  end

  def validate_keyword({:anyOf, subvalidators}, data, vdr) do
    case validate_split(subvalidators, data, vdr) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      # TODO compute branch error of all invalid validations
      {[{_, data} | _], _, vdr} -> {:ok, data, vdr}
      {[], _, vdr} -> {:error, Validator.with_error(vdr, :anyOf, data, validated_schemas: [])}
    end
  end

  def validate_keyword({:allOf, subvalidators}, data, vdr) do
    case validate_split(subvalidators, data, vdr) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      # TODO merge evaluated
      {[{_, data} | _], [], vdr} -> {:ok, data, vdr}
      # TODO merge all error VDRs
      {_, [{_, err_vdr} | _] = _invalid, _vdr} -> {:error, err_vdr}
    end
  end

  def validate_keyword({:if@jsv, {if_vds, then_vds, else_vds}}, data, vdr) do
    case Validator.validate(data, if_vds, vdr) do
      {:ok, _, vdr} ->
        case then_vds do
          nil -> {:ok, data, vdr}
          sub -> Validator.validate(data, sub, vdr)
        end

      {:error, _} ->
        case else_vds do
          nil -> {:ok, data, vdr}
          sub -> Validator.validate(data, sub, vdr)
        end
    end
  end

  def validate_keyword({:contains@jsv, {subschema, n_min, n_max}}, data, vdr) when is_list(data) do
    # We need to keep the validator struct for validated items as they have to
    # be flagged as evaluated for unevaluatedItems support.
    {:ok, count, vdr} =
      data
      |> Enum.with_index()
      |> Validator.iterate(0, vdr, fn {item, index}, count, vdr ->
        case Validator.validate_nested(item, index, subschema, vdr) do
          {:ok, _, vdr} -> {:ok, count + 1, vdr}
          {:error, _} -> {:ok, count, vdr}
        end
      end)

    true = is_integer(n_min)

    cond do
      count < n_min ->
        {:error, Validator.with_error(vdr, :minContains, data, count: count, min_contains: n_min)}

      is_integer(n_max) and count > n_max ->
        {:error, Validator.with_error(vdr, :maxContains, data, count: count, max_contains: n_max)}

      true ->
        {:ok, data, vdr}
    end
  end

  pass validate_keyword({:contains@jsv, _})

  def validate_keyword({:dependentSchemas, schemas_map}, data, vdr) when is_map(data) do
    Validator.iterate(schemas_map, data, vdr, fn
      {parent_key, subschema}, data, vdr when is_map_key(data, parent_key) ->
        Validator.validate(data, subschema, vdr)

      {_, _}, data, vdr ->
        {:ok, data, vdr}
    end)
  end

  pass validate_keyword({:dependentSchemas, _})

  def validate_keyword({:dependentRequired, dep_req}, data, vdr) do
    Validation.validate_dependent_required(dep_req, data, vdr)
  end

  def validate_keyword({:not, schema}, data, vdr) do
    case Validator.validate(data, schema, vdr) do
      {:ok, data, vdr} -> {:error, Validator.with_error(vdr, :not, data, [])}
      # TODO maybe we need to merge "evaluted" properties
      {:error, _} -> {:ok, data, vdr}
    end
  end

  def validate_keyword({:propertyNames, subschema}, data, vdr) when is_map(data) do
    data
    |> Map.keys()
    |> Validator.iterate(data, vdr, fn key, data, vdr ->
      case Validator.validate(key, subschema, vdr) do
        {:ok, _, vdr} -> {:ok, data, vdr}
        {:error, _} = err -> err
      end
    end)
  end

  pass validate_keyword({:propertyNames, _})
  # ---------------------------------------------------------------------------

  # Split the validators between those that validate the data and those who
  # don't.
  IO.warn("@todo return each vdr")

  defp validate_split(validators, data, vdr) do
    # TODO return VDR for each matched or unmatched schema, do not return a
    # global VDR
    {valids, invalids, vdr} =
      Enum.reduce(validators, {[], [], vdr}, fn subvalidator, {valids, invalids, vdr} ->
        case Validator.validate_detach(data, subvalidator, vdr) do
          {:ok, data, vdr} -> {[{subvalidator, data} | valids], invalids, vdr}
          # We continue with the good validator in the acc
          {:error, err_vdr} -> {valids, [{subvalidator, err_vdr} | invalids], vdr}
        end
      end)

    {:lists.reverse(valids), :lists.reverse(invalids), vdr}
  end

  defp with_property_error(vdr, data, {kind, key, _, pattern}) do
    case kind do
      :property -> Validator.with_error(vdr, :properties, data, key: key)
      :pattern -> Validator.with_error(vdr, :patternProperties, data, pattern: pattern, key: key)
      :additional -> Validator.with_error(vdr, :additionalProperties, data, key: key)
    end
  end

  defp validation_enabled?(bld) do
    Builder.vocabulary_enabled?(bld, JSV.Vocabulary.V202012.Validation)
  end

  # ---------------------------------------------------------------------------

  def format_error(:minContains, %{count: count, min_contains: min_contains}, _data) do
    case count do
      0 ->
        "list does not contain any item validating the 'contains' schema, #{min_contains} are required"

      n ->
        "list contains only #{n} item(s) validating the 'contains' schema, #{min_contains} are required"
    end
  end

  def format_error(:maxContains, args, _) do
    %{count: count, max_contains: max_contains} = args
    "list contains more than #{max_contains} items validating the 'contains' schema, found #{count} items"
  end

  def format_error(:item, args, _) do
    %{index: index} = args
    "item at index #{index} does not validate the 'items' schema"
  end

  def format_error(:properties, %{key: key}, _) do
    "property '#{key}' did not conform to the property schema"
  end

  def format_error(:additionalProperties, %{key: key}, _data) do
    "property '#{key}' did not conform to the additionalProperties schema"
  end

  def format_error(:patternProperties, %{pattern: pattern, key: key}, _data) do
    "property '#{key}' did not conform to the patternProperties schema for pattern /#{pattern}/"
  end

  def format_error(:oneOf, %{validated_schemas: []}, _data) do
    {"value did not conform to one of the given schemas", %{}}
  end

  def format_error(:oneOf, %{validated_schemas: _validated_schemas}, _data) do
    {"value validated more than one of the given schemas", %{}}
  end

  def format_error(:anyOf, %{validated_schemas: []}, _data) do
    "value did not conform to any of the given schemas"
  end

  def format_error(:not, _, _data) do
    "value must not validate the schema given in 'not'"
  end
end
