defmodule JSV.ValidationError do
  alias JSV.ErrorFormatter
  @enforce_keys [:errors]
  defexception errors: []

  def of(errors) when is_list(errors) do
    %__MODULE__{errors: errors}
  end

  def format(e) do
    %{valid: false, errors: format_errors(e.errors)}
  end

  defp format_errors(errors) do
    ErrorFormatter.format_errors(errors)
  end

  def message(e) do
    flat_count = length(e.errors)

    groups =
      e.errors
      |> format_errors()
      |> Enum.map(&format_group/1)

    top_message = "json schema validation failed, #{flat_count} errors found"

    IO.iodata_to_binary([top_message | groups])
  end

  defp format_group(group) do
    %{
      valid: false,
      errors: [%{message: _} | _] = sub_errors,
      schemaLocation: schemaLocation,
      instanceLocation: instanceLocation
    } =
      group

    count = length(sub_errors)
    messages = Enum.map_intersperse(sub_errors, "\n", &format_sub_error/1)

    count_fmt =
      if count == 1 do
        "error"
      else
        "errors"
      end

    group_header = ~s[\n\n  at: "#{instanceLocation}" invalidated by "#{schemaLocation}" (#{count} #{count_fmt})\n]
    [group_header | messages]
  end

  defp format_sub_error(err) do
    raise "todo delete kind and no json if empty"
    args_json = Jason.encode_to_iodata!(Map.delete(err, :message) |> dbg())
    ["  * ", err.message, "; ", args_json]
  end
end
