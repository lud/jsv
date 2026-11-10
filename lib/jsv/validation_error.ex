defmodule JSV.ValidationError do
  alias JSV.ErrorFormatter
  alias JSV.Helpers.OptsValidator
  alias JSV.Validator.Error
  alias JSV.Vocabulary.V202012
  alias JSV.Vocabulary.V7

  @moduledoc """
  The data structure returned by `JSV.validate/3` when validation fails.
  """

  @enforce_keys [:errors]
  defexception errors: []

  @type t :: %__MODULE__{errors: [JSV.Validator.Error.t()]}

  @doc """
  Wraps the given `JSV.Validator.Error` list into an `#{inspect(__MODULE__)}`
  exception.
  """
  @spec of([JSV.Validator.Error.t()]) :: t
  def of(errors) when is_list(errors) do
    %__MODULE__{errors: errors}
  end

  @doc """
  Keeps only the errors of the first `:max_errors` invalid locations of the
  data, in data path order.

  An invalid location is a data path with errors and no errors deeper in the
  data. The errors on the parents of the kept locations are kept too, except the
  ones pointing at a child location that was dropped, such as `properties` or
  `items` errors. The branch errors of `anyOf`, `oneOf`, `allOf` and `if` are
  pruned the same way.

  The pruned error can be sent to another process and normalized there.

  ### Options

  * `:max_errors` (positive integer or `:infinity`) - The number of invalid
    locations to keep. The default value is `:infinity`, which keeps all errors.
  """
  @spec prune_errors(t, keyword) :: t
  def prune_errors(%__MODULE__{} = e, opts) do
    case OptsValidator.validate(opts, %{max_errors: :infinity}, &validate_prune_opts/2) do
      %{max_errors: :infinity} -> e
      %{max_errors: max_errors} -> %{e | errors: prune(e.errors, max_errors)}
    end
  end

  defp validate_prune_opts(:max_errors, value) when (is_integer(value) and value > 0) or value == :infinity do
    value
  end

  defp validate_prune_opts(:max_errors, value) do
    OptsValidator.invalid_option!(:max_errors, value, "a positive integer or :infinity")
  end

  defp validate_prune_opts(key, _value) do
    OptsValidator.unknown_option!(key)
  end

  defp prune(errors, max_errors) do
    {locations, parents} =
      Enum.reduce(errors, {%{}, %{}}, fn %Error{data_path: data_path}, {locations, parents} ->
        {Map.put(locations, data_path, true), put_parents(data_path, parents)}
      end)

    kept =
      locations
      |> Map.keys()
      |> Enum.reject(&is_map_key(parents, &1))
      |> Enum.sort_by(&:lists.reverse/1)
      |> Enum.take(max_errors)
      |> Enum.reduce(%{}, fn data_path, kept -> put_parents(data_path, Map.put(kept, data_path, true)) end)

    for error <- errors, kept?(error, kept, locations, parents) do
      prune_branches(error, max_errors)
    end
  end

  defp put_parents([_ | parent], parents) when is_map_key(parents, parent) do
    parents
  end

  defp put_parents([_ | parent], parents) do
    put_parents(parent, Map.put(parents, parent, true))
  end

  defp put_parents([], parents) do
    parents
  end

  # A child location without errors cannot be dropped, so its parent error stays.
  defp kept?(%Error{data_path: data_path} = error, kept, locations, parents) do
    is_map_key(kept, data_path) and
      case child_key(error) do
        nil ->
          true

        key ->
          child_path = [key | data_path]
          is_map_key(kept, child_path) or not (is_map_key(locations, child_path) or is_map_key(parents, child_path))
      end
  end

  defp child_key(%Error{formatter: V202012.Applicator, kind: kind, args: args})
       when kind in [:items, :prefixItems] do
    args[:index]
  end

  defp child_key(%Error{formatter: V202012.Applicator, kind: kind, args: args})
       when kind in [:properties, :additionalProperties, :patternProperties, :propertyNames] do
    args[:key]
  end

  defp child_key(%Error{formatter: V7.Applicator, kind: kind, args: args})
       when kind in [:items, :items_as_prefix, :additionalItems] do
    args[:index]
  end

  defp child_key(_) do
    nil
  end

  defp prune_branches(%Error{formatter: V202012.Applicator, kind: kind, args: args} = error, max_errors)
       when kind in [:anyOf, :oneOf, :allOf, :jsv@if] do
    %{error | args: Enum.map(args, &prune_branch_arg(&1, max_errors))}
  end

  defp prune_branches(error, _max_errors) do
    error
  end

  defp prune_branch_arg({:invalidated, branches}, max_errors) do
    {:invalidated, Enum.map(branches, fn {index, errors} -> {index, prune(:lists.flatten(errors), max_errors)} end)}
  end

  defp prune_branch_arg({key, errors}, max_errors) when key in [:err_if_errors, :after_errors] do
    {key, prune(:lists.flatten(errors), max_errors)}
  end

  defp prune_branch_arg(arg, _max_errors) do
    arg
  end

  @impl true
  def message(e) do
    %{valid: false, details: units} = ErrorFormatter.normalize_error(e, keys: :atoms)
    units_fmt = format_units(units, 0)
    top_message = "json schema validation failed"
    message = [top_message, "\n\n" | units_fmt]
    IO.iodata_to_binary(message)
  end

  defp format_units(units, indent) do
    Enum.map_intersperse(units, "\n\n", &format_unit(&1, indent))
  end

  defp format_unit(unit, indent) do
    %{
      valid: valid?,
      schemaLocation: schema_location,
      instanceLocation: instance_location
    } = unit

    show_valid =
      case valid? do
        true -> [indent(indent), "valid: true", "\n"]
        false -> []
      end

    errors_annots =
      case unit do
        %{errors: list} ->
          annots = Enum.map_intersperse(list, "\n", &format_annot(&1, indent + 1))
          [indent(indent), "errors:\n" | annots]

        _ ->
          []
      end

    [
      [indent(indent), "at: ", inspect(instance_location), "\n"],
      [indent(indent), "by: ", inspect(schema_location), "\n"],
      show_valid,
      errors_annots
    ]
  end

  defp format_annot(err, indent) do
    case err do
      %{details: sub_units} ->
        [
          "#{indent(indent)}- (",
          Atom.to_string(err.kind),
          ") ",
          err.message,
          "\n\n",
          format_units(sub_units, indent + 1)
        ]

      _ ->
        ["#{indent(indent)}- (", Atom.to_string(err.kind), ") ", err.message]
    end
  end

  defp indent(n) when n > 1 do
    [indent(1), indent(n - 1)]
  end

  defp indent(1) do
    "  "
  end

  defp indent(0) do
    []
  end
end
