defmodule JSV.ErrorFormatter do
  alias JSV.Key
  alias JSV.Ref
  alias JSV.ValidationError
  alias JSV.Validator
  alias JSV.Validator.Error

  @moduledoc """
  Error formatting helpers.

  Errors are grouped by:

  * Instance location: the bit of data that was invalidated
  * Schema location: the part of the schema that invalidated it
  * Evaluation path: the path followed from the root to this schema location
  """

  @type annotation :: %{
          required(:valid) => boolean,
          required(:instanceLocation) => binary,
          required(:evaluationPath) => binary,
          required(:schemaLocation) => binary,
          optional(:errors) => [collected_error],
          optional(:detail) => [annotation]
        }

  @type collected_error :: %{
          required(:kind) => atom,
          required(:message) => String.t(),
          optional(:detail) => [annotation]
        }

  @type raw_path :: [raw_path] | binary | integer | atom

  @doc """
  Returns a JSON-able version of the errors contained in the ValidationError.

  This is generatlly useful to generate HTTP API responses or message broker
  responses.
  """
  @spec normalize_error(ValidationError.t()) :: map()
  def normalize_error(%ValidationError{} = e) do
    normalize_error(e, [])
  end

  # TODO maybe remove opts as they are no more used. We may need them if we want
  # to use custom JSON encoding for errors.
  defp normalize_error(e, opts) do
    %{valid: false, details: normalize_errors(e.errors, opts)}
  end

  defp normalize_errors(errors, opts) do
    errors
    |> Enum.group_by(fn
      %Error{data_path: dp, eval_path: ep, schema_path: sp} -> {dp, ep, sp}
      %{valid: _, instanceLocation: _, evaluationPath: _, schemaLocation: _} = already_normalized -> already_normalized
    end)
    |> Enum.map(fn
      {{data_path, eval_path, schema_path}, errors} -> error_annot(data_path, eval_path, schema_path, errors, opts)
      {already_normalized, [already_normalized]} -> already_normalized
    end)
    |> Enum.sort_by(& &1.schemaLocation)
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
        %{message: message, kind: kind}

      {new_kind, message} when is_atom(new_kind) and is_binary(message) ->
        %{message: message, kind: new_kind}

      {message, sub_errors} when is_binary(message) and is_list(sub_errors) ->
        %{message: message, kind: kind, details: normalize_errors(sub_errors, opts)}

      {new_kind, message, sub_errors} when is_atom(new_kind) and is_binary(message) and is_list(sub_errors) ->
        %{message: message, kind: new_kind, details: normalize_errors(sub_errors, opts)}
    end
  end

  @doc """
  Returns an output unit with `valid: true` for the given
  `#{inspect(Validator)}`. This can be substitued to an Error struct in the
  nested details of an error. Mostly used to show multiple validated schemas
  with `:oneOf`.
  """
  @spec valid_annot(Validator.validator(), Validator.context()) :: annotation

  def valid_annot(subschema, vctx) do
    evaluation_path = format_eval_path(vctx.eval_path)

    %{
      valid: true,
      instanceLocation: format_data_path(vctx.data_path),
      evaluationPath: evaluation_path,
      schemaLocation: format_schema_path(subschema)
    }
  end

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

  defp format_eval_path([]) do
    "#"
  end

  defp format_eval_path(rev_eval_path) do
    # map to string but also reverse the path
    iodata = List.foldl(rev_eval_path, [], fn segment, acc -> [?/, format_eval_path_segment(segment) | acc] end)
    IO.iodata_to_binary(["#" | iodata])
  end

  # defp format_schema_path([]) do
  #   "#"
  # end

  defp format_schema_path(rev_path) when is_list(rev_path) do
    format_schema_path(rev_path, [])
  end

  defp format_schema_path({:alias_of, key}) do
    [Key.to_iodata(key)]
  end

  defp format_schema_path(%{schema_path: sp}) do
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
      atom when is_atom(atom) -> Atom.to_string(atom)
      key when is_binary(key) -> key
      index when is_integer(index) -> Integer.to_string(index)
      # {tag, atom} when is_atom(atom) -> [Atom.to_string(tag), ?/, Atom.to_string(atom)]
      {tag, key} when is_binary(key) -> [Atom.to_string(tag), ?/, Ref.escape_json_pointer(key)]
      {tag, index} when is_integer(index) -> [Atom.to_string(tag), ?/, Integer.to_string(index)]
      {_, :"$ref", _} -> "$ref"
      {_, :"$dynamicRef", _} -> "$dynamicRef"
      other -> raise "invalid eval path segment: #{inspect(other)}"
    end
  end
end
