defmodule JSV.ErrorFormatter do
  alias JSV.Helpers.OptsValidator
  alias JSV.Key
  alias JSV.Normalizer
  alias JSV.Ref
  alias JSV.ValidationError
  alias JSV.Validator
  alias JSV.Validator.Error

  @level_intermediary 5
  @level_parent_reported 8
  @level_default 10

  @moduledoc """
  Error formatting helpers.

  Errors are grouped by:

  * Instance location: the bit of data that was invalidated
  * Schema location: the part of the schema that invalidated it
  * Evaluation path: the path followed from the root to this schema location

  ## Error levels

  Each error carries a level, an integer describing how much information the
  error message adds on its own. Consumers that only want actionable messages
  can pass `:min_error_level` to `normalize_error/2` instead of blacklisting
  keywords.

  The levels used by the vocabularies shipped with this library are:

  | Level | Meaning | Example |
  | ----- | ------- | ------- |
  | `#{@level_intermediary}` | The message only points at a deeper error. | `property 'name' did not conform to the property schema` |
  | `#{@level_parent_reported}` | The data is rejected by a rule that belongs to the parent, and the error on the parent reports it. | `value was rejected from boolean schema: false`, under a schema that already reported `additional properties are not allowed but found property 'extra'` |
  | `#{@level_default}` | The error states why the data was rejected. | `value is not of type string` |

  Errors are assigned `#{@level_default}` when `c:JSV.Vocabulary.format_error/3`
  does not return a `:level` key. Custom vocabularies can return any integer,
  including values between or below the ones listed above.
  """

  @type error_unit :: %{
          required(:valid) => boolean,
          required(:instanceLocation) => binary,
          required(:evaluationPath) => binary,
          required(:schemaLocation) => binary,
          optional(:errors) => [keyword_error]
        }

  @type keyword_error :: %{
          required(:kind) => atom,
          required(:message) => String.t(),
          optional(:details) => [error_unit]
        }

  @type level :: integer

  @doc """
  Returns `#{@level_intermediary}`, the level given to errors whose message only
  points at a deeper error.
  """
  @spec level_intermediary :: level
  def level_intermediary do
    @level_intermediary
  end

  @doc """
  Returns `#{@level_parent_reported}`, the level given to errors describing a
  rejection that belongs to the parent data, and that an error on the parent
  already reports.
  """
  @spec level_parent_reported :: level
  def level_parent_reported do
    @level_parent_reported
  end

  @doc """
  Returns `#{@level_default}`, the level given to errors that do not define
  their own level.
  """
  @spec level_default :: level
  def level_default do
    @level_default
  end

  @type raw_path :: [raw_path] | binary | integer | atom

  @doc false
  @spec error_schema :: module
  def error_schema do
    __MODULE__.ValidationErrorSchema
  end

  @type normalize_opt :: {:sort, :asc | :desc} | {:keys, :atoms | :strings} | {:min_error_level, level}

  @default_normalize_options %{sort: :desc, keys: :atoms, min_error_level: 0}

  @doc """
  Returns a JSON-able version of the errors contained in the ValidationError.

  This is generatlly useful to generate HTTP API responses or message broker
  responses.

  ### Options

  * `:sort` (`:asc | :desc`) - Controls the sort direction. Errors are sorted by
    `instanceLocation`. The default value is `:desc`.

  * `:keys` (`:atoms | :strings`) - Define the type of the keys in the
    normalized errors maps.

    While truly "normalized" JSON data should not have atom keys, this option
    defaults to :atoms for backward compatibility reasons.

  * `:min_error_level` (integer) - Drops the errors whose level is below the
    given value, as well as the error units left without any error. See the
    "Error levels" section in `#{inspect(__MODULE__)}`. The default value is
    `0`, which keeps all errors defined by this library.

    Passing `#{@level_parent_reported}` drops the errors that only point at a
    deeper error, and `#{@level_default}` also drops the errors reported by an
    error on the parent data.
  """
  @spec normalize_error(ValidationError.t(), keyword) :: map()
  def normalize_error(%ValidationError{} = e, opts \\ []) do
    opts = OptsValidator.validate(opts, @default_normalize_options, &validate_normalize_opts/2)

    top = %{valid: false, details: filter_units(normalize_errors(e.errors, opts), opts.min_error_level)}
    normalize_keys(top, opts)
  end

  defp validate_normalize_opts(:sort, value) when value in [:asc, :desc] do
    value
  end

  defp validate_normalize_opts(:sort, value) do
    OptsValidator.invalid_option!(:sort, value, ":asc or :desc")
  end

  defp validate_normalize_opts(:keys, value) when value in [:atoms, :strings] do
    value
  end

  defp validate_normalize_opts(:keys, value) do
    OptsValidator.invalid_option!(:keys, value, ":atoms or :strings")
  end

  defp validate_normalize_opts(:min_error_level, value) when is_integer(value) do
    value
  end

  defp validate_normalize_opts(:min_error_level, value) do
    OptsValidator.invalid_option!(:min_error_level, value, "an integer")
  end

  defp validate_normalize_opts(key, _value) do
    OptsValidator.unknown_option!(key)
  end

  # Levels are an implementation detail of the filtering, they are not part of
  # the normalized output, so this pass always runs to strip them.
  defp filter_units(units, min_level) do
    Enum.flat_map(units, &filter_unit(&1, min_level))
  end

  defp filter_unit(%{errors: errors} = unit, min_level) do
    case Enum.flat_map(errors, &filter_keyword_error(&1, min_level)) do
      [] -> []
      kept -> [%{unit | errors: kept}]
    end
  end

  defp filter_unit(unit, _min_level) do
    [unit]
  end

  defp filter_keyword_error(%{level: level}, min_level) when level < min_level do
    []
  end

  # level >= min_level or no level
  defp filter_keyword_error(error, min_level) do
    error = Map.delete(error, :level)

    case error do
      %{details: details} ->
        case filter_units(details, min_level) do
          [] -> [Map.delete(error, :details)]
          kept -> [%{error | details: kept}]
        end

      _ ->
        [error]
    end
  end

  defp normalize_keys(with_atoms, opts) do
    case opts.keys do
      :atoms -> with_atoms
      :strings -> Normalizer.normalize(with_atoms)
    end
  end

  defp normalize_errors(errors, formatter \\ nil, opts) do
    errors
    |> Enum.group_by(fn
      %Error{data_path: dp, eval_path: ep, schema_path: sp} ->
        {dp, ep, sp}

      %{valid: _, instanceLocation: _, evaluationPath: _, schemaLocation: _} = already_normalized ->
        already_normalized

      other when formatter != nil ->
        raise ArgumentError,
              "invalid annotation returned by #{inspect(formatter)}, expected #{inspect(Error)} struct or raw annotation, got: #{other}"

      other ->
        raise ArgumentError, "invalid annotation, expected #{inspect(Error)} struct or raw annotation, got: #{other}"
    end)
    |> Enum.map(fn
      {{data_path, eval_path, schema_path}, errors} -> error_annot(data_path, eval_path, schema_path, errors, opts)
      {already_normalized, [already_normalized]} -> already_normalized
    end)
    |> sort_errors(opts.sort)
  end

  defp sort_errors(errors, order) do
    Enum.sort_by(errors, & &1.instanceLocation, order)
  end

  defp error_annot(rev_data_path, rev_eval_path, rev_schema_path, errors, opts) do
    errors_fmt = Enum.map(errors, &build_error(&1, opts))

    %{
      valid: false,
      errors: errors_fmt,
      instanceLocation: format_data_path(rev_data_path),
      evaluationPath: format_eval_path(rev_eval_path),
      schemaLocation: format_schema_path(rev_schema_path)
    }
  end

  defp build_error(error, opts) do
    %Error{kind: kind, data: data, formatter: formatter, args: args} =
      error

    args_map = Map.new(args)

    case formatter.format_error(kind, args_map, data) do
      message when is_binary(message) ->
        %{message: message, kind: kind, level: @level_default}

      tuple when is_tuple(tuple) ->
        cast_deprecated_error_format(tuple, kind, opts, formatter)

      %{message: message} = map when is_binary(message) ->
        build_error(Map.delete(map, :message), %{message: message, kind: kind, level: @level_default}, formatter, opts)
    end
  end

  defp build_error(map, acc, formatter, opts) do
    Enum.reduce(map, acc, fn
      {:annots, annots}, acc when is_list(annots) ->
        Map.put(acc, :details, normalize_errors(annots, formatter, opts))

      {:kind, kind}, acc when is_binary(kind) when is_atom(kind) ->
        Map.put(acc, :kind, kind)

      {:level, level}, acc when is_integer(level) ->
        Map.put(acc, :level, level)

      {k, v}, _ when k in [:annots, :kind, :level] ->
        raise "invalid format_error value for key #{inspect(k)} from formatter #{inspect(formatter)}: #{inspect(v)}"

      {k, v}, _ ->
        IO.warn("unknown format_error value with key #{inspect(k)} from formatter #{inspect(formatter)}: #{inspect(v)}")
        acc
    end)
  end

  defp cast_deprecated_error_format(tuple, kind, opts, formatter) do
    :ok = warn_deprecated_format_error(formatter, tuple)

    case tuple do
      {new_kind, message} when is_atom(new_kind) and is_binary(message) ->
        %{message: message, kind: new_kind, level: @level_default}

      {message, sub_errors} when is_binary(message) and is_list(sub_errors) ->
        %{message: message, kind: kind, level: @level_default, details: normalize_errors(sub_errors, formatter, opts)}

      {new_kind, message, sub_errors} when is_atom(new_kind) and is_binary(message) and is_list(sub_errors) ->
        %{
          message: message,
          kind: new_kind,
          level: @level_default,
          details: normalize_errors(sub_errors, formatter, opts)
        }
    end
  end

  if Mix.env() == :test do
    @spec warn_deprecated_format_error(module, term) :: :ok
    defp warn_deprecated_format_error(formatter, value) do
      if Process.get({__ENV__.file, __ENV__.line}) == 1 do
        :ok
      else
        raise """
        deprecated format_error return value from #{inspect(formatter)}

        Expected message or map but got:
        #{inspect(value, pretty: true)}
        """
      end
    end
  else
    defp warn_deprecated_format_error(formatter, _) do
      IO.warn("deprecated format_error return value from #{inspect(formatter)}")
    end
  end

  @doc """
  Returns an output unit with `valid: true` for the given
  `#{inspect(Validator)}`. This can be substitued to an Error struct in the
  nested details of an error. Mostly used to show multiple validated schemas
  with `:oneOf`.
  """
  @spec valid_annot(Validator.validator(), Validator.context()) :: error_unit

  def valid_annot(subschema, vctx) do
    evaluation_path = format_eval_path(vctx.eval_path)

    %{
      valid: true,
      instanceLocation: format_data_path(vctx.data_path),
      evaluationPath: evaluation_path,
      schemaLocation: format_schema_path(subschema)
    }
  end

  @doc """
  Formats a data path into a JSON pointer string prefixed with `#`.

  The path is given in reverse order, as stored in errors and validation
  contexts. For instance, a path pointing to the first element of a `"users"`
  array is given as `[0, "users"]` and formatted as `"#/users/0"`.
  """
  @spec format_data_path(raw_path) :: String.t()
  def format_data_path([]) do
    "#"
  end

  def format_data_path(rev_data_path) do
    iodata =
      List.foldl(rev_data_path, [], fn
        index, acc when is_integer(index) -> [?/, Integer.to_string(index) | acc]
        key, acc -> [?/, Ref.escape_json_pointer(key) | acc]
      end)

    IO.iodata_to_binary(["#" | iodata])
  end

  @doc false
  @spec format_eval_path(list) :: binary
  def format_eval_path([]) do
    "#"
  end

  def format_eval_path(rev_eval_path) do
    # map to string but also reverse the path
    iodata = List.foldl(rev_eval_path, [], fn segment, acc -> [?/, format_eval_path_segment(segment) | acc] end)
    IO.iodata_to_binary(["#" | iodata])
  end

  @doc false
  @spec format_schema_path([term] | Validator.validator()) :: binary
  def format_schema_path(rev_path)

  def format_schema_path([]) do
    "#"
  end

  def format_schema_path(rev_path) when is_list(rev_path) do
    format_schema_path(rev_path, [])
  end

  def format_schema_path({:alias_of, key}) do
    Key.to_iodata(key)
  end

  def format_schema_path(%{schema_path: sp}) do
    format_schema_path(sp)
  end

  defp format_schema_path([segment, next | rev_path], acc) do
    format_schema_path([next | rev_path], [?/, format_eval_path_segment(segment) | acc])
  end

  defp format_schema_path([last], acc) do
    final_path =
      case last do
        :root -> IO.iodata_to_binary(["#" | acc])
        id when is_binary(id) -> [id, "#" | acc]
      end

    IO.iodata_to_binary(final_path)
  end

  defp format_eval_path_segment(item) do
    case item do
      atom when is_atom(atom) -> Ref.escape_json_pointer(Atom.to_string(atom))
      key when is_binary(key) -> Ref.escape_json_pointer(key)
      index when is_integer(index) -> Integer.to_string(index)
      {tag, key} when is_binary(key) -> [Atom.to_string(tag), ?/, Ref.escape_json_pointer(key)]
      {tag, index} when is_integer(index) -> [Atom.to_string(tag), ?/, Integer.to_string(index)]
      {_, :"$ref", _} -> "$ref"
      {_, :"$dynamicRef", _} -> "$dynamicRef"
      other -> raise "invalid eval path segment: #{inspect(other)}"
    end
  end
end
