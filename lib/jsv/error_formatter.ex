defmodule JSV.ErrorFormatter do
  alias JSV.Key
  alias JSV.Ref
  alias JSV.Validator.Error

  @moduledoc """
  Error formatting loosely following the guidelines described at
  https://json-schema.org/blog/posts/fixing-json-schema-output

  Errors are grouped by similar instance location (the bit of data that was
  invalidated) and schema location (the part of the schema that invalidated it).
  """

  def format_errors(errors) do
    errors
    |> Enum.group_by(fn %Error{data_path: dp, eval_path: ep} -> {dp, ep} end)
    # reverse the data path once by group so we can properly sort the errors
    # with it
    |> Enum.map(fn {{data_path, eval_path}, errors} -> format_group(data_path, eval_path, errors) end)
    |> Enum.sort_by(& &1.instanceLocation)
  end

  defp format_group(data_path, eval_path, errors) do
    {absolute_location, keyword_location} = format_keyword_paths(eval_path)

    errors_fmt = Enum.map(errors, &Error.format/1)

    %{
      valid: false,
      errors: errors_fmt,
      instanceLocation: format_data_path(data_path),
      evaluationPath: keyword_location,
      schemaLocation: absolute_location
    }
  end

  defp format_data_path([]) do
    ""
  end

  defp format_data_path(data_path) do
    "/" <>
      (data_path
       |> :lists.reverse()
       |> Enum.map_join("/", fn
         index when is_integer(index) -> Integer.to_string(index)
         key -> Ref.escape_json_pointer(key)
       end))
  end

  defp format_keyword_paths([]) do
    {"", ""}
  end

  defp format_keyword_paths(eval_path) do
    flat_path = flatten_path(eval_path)

    absolute_path =
      flat_path
      |> take_last_ns_path_segments([])
      |> format_path()

    schema_path = flat_path_to_schema_path(flat_path)

    {absolute_path, schema_path}
  end

  @doc false
  def format_schema_path(eval_path) do
    flat_path = flatten_path(eval_path)

    flat_path_to_schema_path(flat_path)
  end

  defp flat_path_to_schema_path(flat_path) do
    flat_path
    |> take_eval_path_segments([])
    |> format_path()
  end

  # eval path is built in reverse while iterating the schemas by consing to the
  # list. But for convenience, adding multiple items to the list is done by
  # keeping them ordered. For instance, we are consing ["properties","foo"] and
  # not ["foo","properties"].
  #
  # Here we need to flatten the list on only one level while reversing the
  # sublists.
  defp flatten_path(list) do
    case list do
      [h | t] when is_list(h) -> :lists.reverse(h, flatten_path(t))
      [h | t] -> [h | flatten_path(t)]
      [] -> []
    end
  end

  defp take_last_ns_path_segments(list, acc) do
    case list do
      [h | t] when is_integer(h) when is_atom(h) when is_binary(h) -> take_last_ns_path_segments(t, [h | acc])
      # stop at the first scope changing element
      [{:ref, _, key} | _] -> [{:ns, Key.namespace_of(key)} | acc]
      [{:alias_of, ns} | _] -> [{:ns, ns} | acc]
      [] -> acc
    end
  end

  defp take_eval_path_segments(list, acc) do
    case list do
      [h | t] when is_integer(h) when is_atom(h) when is_binary(h) -> take_eval_path_segments(t, [h | acc])
      # # stop at the first scope changing element
      [{:ref, keyword, _} | t] -> take_eval_path_segments(t, [keyword | acc])
      [{:alias_of, _} | t] -> take_eval_path_segments(t, acc)
      [] -> acc
    end
  end

  defp format_path(items) do
    items
    |> Enum.map(fn
      {:ns, _} = item -> format_path_segment(item)
      item -> ["/", format_path_segment(item)]
    end)
    |> IO.iodata_to_binary()
  end

  defp format_path_segment(item) do
    case item do
      atom when is_atom(atom) -> Atom.to_string(atom)
      key when is_binary(key) -> Ref.escape_json_pointer(key)
      index when is_integer(index) -> Integer.to_string(index)
      {:ns, ns} -> ns
      other -> raise "invalid eval path segment: #{inspect(other)}"
    end
  end
end
