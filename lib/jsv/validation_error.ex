defmodule JSV.ValidationError do
  alias JSV.ErrorFormatter
  alias JSV.Helpers.OptsValidator
  alias JSV.Validator.Error
  alias JSV.Vocabulary.V202012

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
  Drops errors from a validation error, so it is cheaper to copy and to
  normalize.

  Errors are first filtered by level, then only the errors of the first
  `:max_errors` invalid locations of the data are kept, in data path order.
  Without options, the error is returned unchanged.

  An invalid location is a data path with errors and no errors deeper in the
  data. The errors on the parents of the kept locations are kept too, except the
  errors at the `JSV.ErrorFormatter.level_intermediary/0` level with a `key` or
  `index` arg, which only stay when the child location they point at is kept.

  The branch errors of `anyOf`, `oneOf`, `allOf` and `if` are pruned the same
  way, and each branch keeps up to `:max_errors` locations of its own. With
  nested branches, the total number of kept locations can be higher than
  `:max_errors`.

  Levels are read from the error args. Levels returned by
  `c:JSV.Vocabulary.format_error/3` are applied by
  `JSV.ErrorFormatter.normalize_error/2`.

  ### Options

  * `:min_error_level` (integer) - Drops the errors whose level is below the
    given value. When omitted, errors of all levels are kept.
  * `:max_errors` (positive integer or `:infinity`) - The number of invalid
    locations to keep. When omitted or `:infinity`, all locations are kept.
  """
  @spec prune_errors(t, keyword) :: t
  def prune_errors(%__MODULE__{} = e, opts) do
    case OptsValidator.validate(opts, %{max_errors: :infinity}, &validate_prune_opts/2) do
      %{max_errors: :infinity} = opts when map_size(opts) == 1 -> e
      opts -> %{e | errors: prune(e.errors, opts)}
    end
  end

  # TODO: share the validation of :min_error_level and :max_errors with
  # JSV.ErrorFormatter.normalize_error/2.
  defp validate_prune_opts(:min_error_level, value) when is_integer(value) do
    value
  end

  defp validate_prune_opts(:min_error_level, value) do
    OptsValidator.invalid_option!(:min_error_level, value, "an integer")
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

  defp prune(errors, opts) do
    errors =
      case opts do
        %{min_error_level: min_level} -> Enum.filter(errors, &(args_level(&1) >= min_level))
        _ -> errors
      end

    errors =
      case opts do
        %{max_errors: max_errors} when is_integer(max_errors) -> prune_locations(errors, max_errors)
        _ -> errors
      end

    Enum.map(errors, &prune_branches(&1, opts))
  end

  defp prune_locations(errors, max_errors) do
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

    Enum.filter(errors, &kept?(&1, kept, locations, parents))
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

  defp child_key(%Error{args: args} = error) do
    if args_level(error) == ErrorFormatter.level_intermediary() do
      args[:key] || args[:index]
    end
  end

  defp args_level(%Error{args: args}) do
    case args[:level] do
      level when is_integer(level) -> level
      _ -> ErrorFormatter.level_cause()
    end
  end

  defp prune_branches(%Error{formatter: V202012.Applicator, kind: kind, args: args} = error, opts)
       when kind in [:anyOf, :oneOf, :allOf, :jsv@if] do
    %{error | args: Enum.map(args, &prune_branch_arg(&1, opts))}
  end

  defp prune_branches(error, _opts) do
    error
  end

  defp prune_branch_arg({:invalidated, branches}, opts) do
    {:invalidated, Enum.map(branches, fn {index, errors} -> {index, prune(:lists.flatten(errors), opts)} end)}
  end

  defp prune_branch_arg({key, errors}, opts) when key in [:err_if_errors, :after_errors] do
    {key, prune(:lists.flatten(errors), opts)}
  end

  defp prune_branch_arg(arg, _opts) do
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
