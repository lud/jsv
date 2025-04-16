defmodule JSV.Vocabulary.V202012.Applicator do
  alias JSV.Builder
  alias JSV.ErrorFormatter
  alias JSV.Helpers.EnumExt
  alias JSV.Validator
  alias JSV.Vocabulary
  alias JSV.Vocabulary.V202012.Validation
  use JSV.Vocabulary, priority: 200

  @moduledoc """
  Implementation for the `https://json-schema.org/draft/2020-12/vocab/applicator`
  vocabulary.
  """

  @impl true
  def init_validators(_) do
    []
  end

  take_keyword :properties, properties, acc, builder, _ do
    properties
    |> EnumExt.reduce_ok({%{}, builder}, fn {k, pschema}, {acc, builder} ->
      # Support properties as atoms for atom schemas
      k =
        if is_atom(k) do
          Atom.to_string(k)
        else
          k
        end

      case Builder.build_sub(pschema, [properties: k], builder) do
        {:ok, subvalidators, builder} -> {:ok, {Map.put(acc, k, subvalidators), builder}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, builder}} -> {:ok, [{:properties, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :additionalProperties, additional_properties, acc, builder, _ do
    take_sub(:additionalProperties, additional_properties, acc, builder)
  end

  take_keyword :patternProperties, pattern_properties, acc, builder, _ do
    pattern_properties
    |> EnumExt.reduce_ok({%{}, builder}, fn {k, pschema}, {acc, builder} ->
      with {:ok, re} <- Regex.compile(k),
           {:ok, subvalidators, builder} <- Builder.build_sub(pschema, [patternProperties: k], builder) do
        {:ok, {Map.put(acc, {k, re}, subvalidators), builder}}
      end
    end)
    |> case do
      {:ok, {subvalidators, builder}} -> {:ok, [{:patternProperties, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :items, items, acc, builder, _ do
    take_sub(:items, items, acc, builder)
  end

  take_keyword :prefixItems, prefix_items when is_list(prefix_items), acc, builder, _ do
    case build_sub_list(:prefixItems, prefix_items, builder) do
      {:ok, subvalidators, builder} -> {:ok, [{:prefixItems, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :allOf, [_ | _] = all_of, acc, builder, _ do
    case build_sub_list(:allOf, all_of, builder) do
      {:ok, subvalidators, builder} -> {:ok, [{:allOf, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :anyOf, [_ | _] = any_of, acc, builder, _ do
    case build_sub_list(:anyOf, any_of, builder) do
      {:ok, subvalidators, builder} -> {:ok, [{:anyOf, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :oneOf, [_ | _] = one_of, acc, builder, _ do
    case build_sub_list(:oneOf, one_of, builder) do
      {:ok, subvalidators, builder} -> {:ok, [{:oneOf, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :if, if_schema, acc, builder, _ do
    take_sub(:if, if_schema, acc, builder)
  end

  take_keyword :then, then, acc, builder, _ do
    take_sub(:then, then, acc, builder)
  end

  take_keyword :else, else_schema, acc, builder, _ do
    take_sub(:else, else_schema, acc, builder)
  end

  take_keyword :propertyNames, property_names, acc, builder, _ do
    take_sub(:propertyNames, property_names, acc, builder)
  end

  take_keyword :contains, contains, acc, builder, _ do
    take_sub(:contains, contains, acc, builder)
  end

  take_keyword :maxContains, max_contains, acc, builder, _ do
    if validation_enabled?(builder) do
      take_integer(:maxContains, max_contains, acc, builder)
    else
      :ignore
    end
  end

  take_keyword :minContains, min_contains, acc, builder, _ do
    if validation_enabled?(builder) do
      take_integer(:minContains, min_contains, acc, builder)
    else
      :ignore
    end
  end

  take_keyword :dependentSchemas, dependent_schemas when is_map(dependent_schemas), acc, builder, _ do
    dependent_schemas
    |> EnumExt.reduce_ok({%{}, builder}, fn {k, depschema}, {acc, builder} ->
      case Builder.build_sub(depschema, [k], builder) do
        {:ok, subvalidators, builder} -> {:ok, {Map.put(acc, k, subvalidators), builder}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, builder}} -> {:ok, [{:dependentSchemas, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  take_keyword :dependencies, map when is_map(map), acc, builder, raw_schema do
    {dependent_schemas, dependent_required} =
      Enum.reduce(map, {[], []}, fn {key, subschema}, {dependent_schemas, dependent_required} ->
        cond do
          is_list(subschema) && Enum.all?(subschema, &is_binary/1) ->
            {dependent_schemas, [{key, subschema} | dependent_required]}

          is_boolean(subschema) || is_map(subschema) ->
            {[{key, subschema} | dependent_schemas], dependent_required}
        end
      end)

    with {:ok, acc, builder} <-
           handle_keyword({"dependentSchemas", Map.new(dependent_schemas)}, acc, builder, raw_schema) do
      {:ok, [{:dependentRequired, dependent_required} | acc], builder}
    end
  end

  take_keyword :not, subschema, acc, builder, _ do
    take_sub(:not, subschema, acc, builder)
  end

  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  defp build_sub_list(keyword, subschemas, builder) do
    subs =
      subschemas
      |> Enum.with_index()
      |> EnumExt.reduce_ok({[], builder}, fn {subschema, index}, {acc, builder} ->
        case Builder.build_sub(subschema, [path_segment(keyword, index)], builder) do
          {:ok, subvalidators, builder} -> {:ok, {[subvalidators | acc], builder}}
          {:error, _} = err -> err
        end
      end)

    case subs do
      {:ok, {subvalidators, builder}} -> {:ok, :lists.reverse(subvalidators), builder}
      {:error, _} = err -> err
    end
  end

  # ---------------------------------------------------------------------------

  @impl true
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
        Keyword.put(validators, :jsv@props, {properties, pattern_properties, additional_properties})
    end
  end

  defp finalize_items(validators) do
    {items, validators} = Keyword.pop(validators, :items, nil)
    {prefix_items, validators} = Keyword.pop(validators, :prefixItems, nil)

    case {items, prefix_items} do
      {nil, nil} -> validators
      some -> Keyword.put(validators, :jsv@array, some)
    end
  end

  defp finalize_if_then_else(validators) do
    {if_vds, validators} = Keyword.pop(validators, :if, nil)
    {then_vds, validators} = Keyword.pop(validators, :then, nil)
    {else_vds, validators} = Keyword.pop(validators, :else, nil)

    case {if_vds, then_vds, else_vds} do
      {nil, _, _} -> validators
      some -> Keyword.put(validators, :jsv@if, some)
    end
  end

  defp finalize_contains(validators) do
    {contains, validators} = Keyword.pop(validators, :contains, nil)
    {min_contains, validators} = Keyword.pop(validators, :minContains, 1)
    {max_contains, validators} = Keyword.pop(validators, :maxContains, nil)

    case {contains, min_contains, max_contains} do
      {nil, _, _} -> validators
      some -> Keyword.put(validators, :jsv@contains, some)
    end
  end

  # ---------------------------------------------------------------------------

  @impl true
  def validate(data, vds, vctx) do
    Validator.reduce(vds, data, vctx, &validate_keyword/3)
  end

  defp properties_validations(_data, nil) do
    []
  end

  defp properties_validations(data, properties) do
    Enum.flat_map(properties, fn
      {key, subschema} when is_map_key(data, key) -> [{:properties, key, subschema, nil}]
      _ -> []
    end)
  end

  defp pattern_properties_validations(_data, nil) do
    []
  end

  defp pattern_properties_validations(data, pattern_properties) do
    for {{pattern, re}, subschema} <- pattern_properties,
        {key, _} <- data,
        Regex.match?(re, key) do
      {:patternProperties, key, subschema, pattern}
    end
  end

  defp additional_properties_validations(data, schema, other_validations) do
    Enum.flat_map(data, fn {key, _} ->
      if List.keymember?(other_validations, key, 1) do
        []
      else
        [{:additionalProperties, key, schema, nil}]
      end
    end)
  end

  @doc false
  @spec validate_keyword({atom | binary, term}, Vocabulary.data(), Validator.context()) :: Validator.result()
  def validate_keyword({:jsv@props, {props_schemas, patterns_schemas, additionals_schema}}, data, vctx)
      when is_map(data) do
    for_props = properties_validations(data, props_schemas)
    for_patterns = pattern_properties_validations(data, patterns_schemas)

    validations = for_props ++ for_patterns

    for_additional =
      case additionals_schema do
        nil -> []
        _ -> additional_properties_validations(data, additionals_schema, validations)
      end

    all_validations = for_additional ++ validations

    # Note: if a property is validated by both :properties and
    # :patternProperties, casted data from the first schema is evaluted by the
    # second. A possible fix is to discard previously casted value on second
    # schema but we will loose all cast from nested schemas.

    Validator.reduce(all_validations, data, vctx, fn
      {kind, key, subschema, pattern} = propcase, data, vctx ->
        eval_path = path_segment(kind, pattern || key)

        case Validator.validate_in(Map.fetch!(data, key), key, eval_path, subschema, vctx) do
          {:ok, casted, vctx} -> {:ok, Map.put(data, key, casted), vctx}
          {:error, vctx} -> {:error, with_property_error(vctx, data, propcase)}
        end
    end)
  end

  pass validate_keyword({:jsv@props, _})

  def validate_keyword({:jsv@array, {items_schema, prefix_items_schemas}}, data, vctx) when is_list(data) do
    prefix_stream =
      case prefix_items_schemas do
        nil -> []
        list -> Enum.map(list, &{:prefixItems, &1})
      end

    rest_stream = Stream.cycle([{:items, items_schema}])
    all_stream = Stream.concat(prefix_stream, rest_stream)
    data_items_index = Stream.with_index(data)

    # Zipping items with their schemas. If the schema only specifies
    # prefixItems, then items_schema is nil and the zip will associate with nil.
    zipped =
      Enum.zip_with([data_items_index, all_stream], fn
        [{data_item, index}, {kind, schema}] -> {kind, index, data_item, schema}
      end)

    {validated_items, vctx} = validate_items(zipped, data, vctx)
    Validator.return(validated_items, vctx)
  end

  pass validate_keyword({:jsv@array, _})

  def validate_keyword({:oneOf, subschemas}, data, vctx) do
    case validate_split(subschemas, :oneOf, data, vctx) do
      {[{_, data, _subschema_, _detached_vctx}], _, vctx} ->
        {:ok, data, vctx}

      {[], _, _} ->
        # TODO compute branch error of all invalid
        {:error, Validator.with_error(vctx, :oneOf, data, validated: [])}

      # with oneOf we also return the subschema so we can compute the
      # schemaLocation of the extra validated subschemas
      {[_, _ | _] = too_much, _, _} ->
        validated = Enum.map(too_much, fn {index, _, subschema, vctx} -> {index, subschema, vctx} end)

        {:error, Validator.with_error(vctx, :oneOf, data, validated: validated)}
    end
  end

  def validate_keyword({:anyOf, subschemas}, data, vctx) do
    # TODO return early once we validate at least one schema. There is no need
    # to continue validation afterwards.
    case validate_split(subschemas, :anyOf, data, vctx) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      {[{_, data, _subschema, _detached_vctx} | _], _, vctx} ->
        {:ok, data, vctx}

      {[], invalids, vctx} ->
        {:error, Validator.with_error(vctx, :anyOf, data, invalidated: invalids)}
    end
  end

  def validate_keyword({:allOf, subschemas}, data, vctx) do
    case validate_split(subschemas, :allOf, data, vctx) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily. TODO if multiple casts are applied we should use
      # that data recursively.
      {[{_, data, _subschema_, _detached_vctx} | _], [], vctx} ->
        {:ok, data, vctx}

      {_, invalids, vctx} ->
        {:error, Validator.with_error(vctx, :allOf, data, invalidated: invalids)}
    end
  end

  def validate_keyword({:jsv@if, {if_vds, then_vds, else_vds}}, data, vctx) do
    {to_validate, vctx, eval_path, meta} =
      case Validator.validate_detach(data, "if", if_vds, vctx) do
        {:ok, _, ok_vctx} ->
          {then_vds, Validator.merge_evaluated(vctx, ok_vctx), "then", ok_if_vctx: ok_vctx, ok_if_subschema: if_vds}

        {:error, err_vctx} ->
          {else_vds, vctx, "else", err_if_vctx: err_vctx}
      end

    case to_validate do
      nil ->
        {:ok, data, vctx}

      sub ->
        case Validator.validate_detach(data, eval_path, sub, vctx) do
          {:ok, data, ok_vctx} ->
            {:ok, data, Validator.merge_evaluated(vctx, ok_vctx)}

          {:error, err_vctx} ->
            {:error, Validator.with_error(vctx, :jsv@if, data, [{:after_err_vctx, err_vctx} | meta])}
        end
    end
  end

  def validate_keyword({:jsv@contains, {subschema, n_min, n_max}}, data, vctx) when is_list(data) do
    # We need to keep the validator struct for validated items as they have to
    # be flagged as evaluated for unevaluatedItems support.
    {:ok, count, vctx} =
      data
      |> Enum.with_index()
      |> Validator.reduce(0, vctx, fn {item, index}, count, vctx ->
        case Validator.validate_in(item, index, :contains, subschema, vctx) do
          {:ok, _, vctx} -> {:ok, count + 1, vctx}
          {:error, _} -> {:ok, count, vctx}
        end
      end)

    true = is_integer(n_min)

    cond do
      count < n_min ->
        {:error, Validator.with_error(vctx, :minContains, data, count: count, min_contains: n_min)}

      is_integer(n_max) and count > n_max ->
        {:error, Validator.with_error(vctx, :maxContains, data, count: count, max_contains: n_max)}

      true ->
        {:ok, data, vctx}
    end
  end

  pass validate_keyword({:jsv@contains, _})

  def validate_keyword({:dependentSchemas, schemas_map}, data, vctx) when is_map(data) do
    Validator.reduce(schemas_map, data, vctx, fn
      {parent_key, subschema}, data, vctx when is_map_key(data, parent_key) ->
        Validator.validate(data, subschema, vctx)

      {_, _}, data, vctx ->
        {:ok, data, vctx}
    end)
  end

  pass validate_keyword({:dependentSchemas, _})

  def validate_keyword({:dependentRequired, dep_req}, data, vctx) do
    Validation.validate_dependent_required(dep_req, data, vctx)
  end

  def validate_keyword({:not, schema}, data, vctx) do
    case Validator.validate(data, schema, vctx) do
      {:ok, data, vctx} -> {:error, Validator.with_error(vctx, :not, data, [])}
      # TODO maybe we need to merge "evaluted" properties
      {:error, _} -> {:ok, data, vctx}
    end
  end

  def validate_keyword({:propertyNames, subschema}, data, vctx) when is_map(data) do
    data
    |> Map.keys()
    |> Validator.reduce(data, vctx, fn key, data, vctx ->
      case Validator.validate(key, subschema, vctx) do
        {:ok, _, vctx} -> {:ok, data, vctx}
        {:error, _} = err -> err
      end
    end)
  end

  pass validate_keyword({:propertyNames, _})

  # ---------------------------------------------------------------------------

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp path_segment(kind, arg) do
    case kind do
      #
      # use the argument
      :prefixItems -> {:prefixItems, arg}
      :properties -> {:properties, arg}
      :anyOf -> {:anyOf, arg}
      :allOf -> {:allOf, arg}
      :oneOf -> {:oneOf, arg}
      :patternProperties -> {:patternProperties, arg}
      #
      # no need for the argument
      :items -> :items
      :additionalProperties -> :additionalProperties
      #
      # Draft 7 support
      :items_as_prefix -> {:items, arg}
      :additionalItems -> :additionalItems
    end
  end

  defp validate_split(subschemas, kind, data, vctx) do
    # TODO return vctx for each matched or unmatched schema, do not return a
    # global vctx
    {valids, invalids, vctx, _} =
      Enum.reduce(subschemas, {[], [], vctx, _index = 0}, fn subschema, {valids, invalids, vctx, index} ->
        case Validator.validate_detach(data, {kind, index}, subschema, vctx) do
          {:ok, data, detached_vctx} ->
            # Valid subschemas must produce "annotations" for the data they
            # validate. For us it means that we merge the evaluated properties
            # for successful schemas.
            vctx = Validator.merge_evaluated(vctx, detached_vctx)
            {[{index, data, subschema, detached_vctx} | valids], invalids, vctx, index + 1}

          {:error, err_vctx} ->
            {valids, [{index, err_vctx} | invalids], vctx, index + 1}
        end
      end)

    {:lists.reverse(valids), :lists.reverse(invalids), vctx}
  end

  # Special case for additionalProperties: false
  defp with_property_error(vctx, data, {:additionalProperties, key, %JSV.BooleanSchema{valid?: false}, _pattern}) do
    Validator.with_error(vctx, :additionalProperties, data, key: key, boolean_schema_false: true)
  end

  defp with_property_error(vctx, data, {kind, key, _, pattern}) do
    case kind do
      :properties -> Validator.with_error(vctx, :properties, data, key: key)
      :patternProperties -> Validator.with_error(vctx, :patternProperties, data, pattern: pattern, key: key)
      :additionalProperties -> Validator.with_error(vctx, :additionalProperties, data, key: key)
    end
  end

  defp validation_enabled?(builder) do
    Builder.vocabulary_enabled?(builder, JSV.Vocabulary.V202012.Validation)
  end

  @doc false
  # This function is public for draft7, with support of :additionalItems
  #
  # Validate all items in a stream of {kind, index, item_data, subschema}.
  # The subschema can be nil which makes the item automatically valid.
  @spec validate_items(Enumerable.t(), list, Validator.context(), module) :: {Enumerable.t(), Validator.context()}
  def validate_items(stream, data, vctx, error_formatter \\ __MODULE__) do
    {rev_items, vctx} =
      Enum.reduce(stream, {[], vctx}, fn
        {_kind, _index, data_item, nil = _subschema}, {casted, vctx} ->
          # TODO add evaluated path to validator
          {[data_item | casted], vctx}

        {kind, index, data_item, subschema}, {casted, vctx} ->
          eval_path = path_segment(kind, index)

          case Validator.validate_in(data_item, index, eval_path, subschema, vctx) do
            {:ok, casted_item, vctx} ->
              {[casted_item | casted], vctx}

            {:error, vctx} ->
              {[data_item | casted], JSV.Validator.__with_error__(error_formatter, vctx, kind, data, index: index)}
          end
      end)

    {:lists.reverse(rev_items), vctx}
  end

  # ---------------------------------------------------------------------------

  @impl true
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

  def format_error(:items, args, _) do
    %{index: index} = args
    "item at index #{index} does not validate the 'items' schema"
  end

  def format_error(:prefixItems, args, _) do
    %{index: index} = args
    "item at index #{index} does not validate the 'prefixItems[#{index}]' schema"
  end

  def format_error(:properties, %{key: key}, _) do
    "property '#{key}' did not conform to the property schema"
  end

  def format_error(:additionalProperties, %{key: key, boolean_schema_false: true}, _data) do
    "additional properties are not allowed but found property '#{key}'"
  end

  def format_error(:additionalProperties, %{key: key}, _data) do
    "property '#{key}' did not conform to the additionalProperties schema"
  end

  def format_error(:patternProperties, %{pattern: pattern, key: key}, _data) do
    "property '#{key}' did not conform to the patternProperties schema for pattern /#{pattern}/"
  end

  def format_error(:oneOf, %{validated: []}, _data) do
    "value did not conform to any of the given schemas"
  end

  def format_error(:oneOf, %{validated: validated}, _data) do
    # Best effort for now, we are not accumulating annotations for valid data,
    # so we only return the paths of the multiples schemas that were validated
    validated =
      Enum.map(validated, fn {_index, subschema, vctx} ->
        ErrorFormatter.valid_annot(subschema, vctx)
      end)

    # {"value did conform to more than one of the given schemas", %{validated: validated}}
    {"value did conform to more than one of the given schemas", validated}
  end

  def format_error(:anyOf, %{invalidated: invalidated}, _data) do
    sub_errors = format_invalidated_subs(invalidated)

    {"value did not conform to any of the given schemas", sub_errors}
  end

  def format_error(:allOf, %{invalidated: invalidated}, _data) do
    sub_errors = format_invalidated_subs(invalidated)

    {"value did not conform to all of the given schemas", sub_errors}
  end

  def format_error(:not, _, _data) do
    "value must not validate the schema given in 'not'"
  end

  def format_error(:jsv@if, meta, _data) do
    case meta do
      %{ok_if_subschema: if_schema, ok_if_vctx: ok_if_vctx, after_err_vctx: then_err} ->
        {:"if/then", "value validated 'if' but not 'then'",
         [ErrorFormatter.valid_annot(if_schema, ok_if_vctx)] ++ Validator.flat_errors(then_err)}

      %{err_if_vctx: err_if_vctx, after_err_vctx: else_err} ->
        {:"if/else", "value validated neither 'if' nor 'else'",
         Validator.flat_errors(err_if_vctx) ++ Validator.flat_errors(else_err)}
    end
  end

  defp format_invalidated_subs(invalidated) do
    Enum.flat_map(invalidated, fn {_index, vctx} -> Validator.flat_errors(vctx) end)
  end
end
