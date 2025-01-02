defmodule JSV.Ref do
  alias __MODULE__
  alias JSV.RNS

  @moduledoc """
  Representation of a JSON Schema reference (`$ref` or `$dynamicRef`).
  """

  defstruct ns: nil, kind: nil, fragment: nil, arg: nil, dynamic?: false

  @type t :: %__MODULE__{}
  @type ns :: binary | :root

  @spec parse(binary, ns) :: {:ok, t} | {:error, term}
  def parse(url, current_ns) do
    do_parse(url, current_ns, false)
  end

  @spec parse_dynamic(binary, ns) :: {:ok, t} | {:error, term}
  def parse_dynamic(url, current_ns) do
    do_parse(url, current_ns, true)
  end

  defp do_parse(url, current_ns, dynamic?) do
    uri = URI.parse(url)
    {kind, normalized_fragment, arg} = parse_fragment(uri.fragment)

    dynamic? = dynamic? and kind == :anchor

    with {:ok, ns} <- RNS.derive(current_ns, url) do
      {:ok, %Ref{ns: ns, kind: kind, fragment: normalized_fragment, arg: arg, dynamic?: dynamic?}}
    end
  end

  defp parse_fragment(nil) do
    {:top, nil, []}
  end

  defp parse_fragment("") do
    {:top, nil, []}
  end

  defp parse_fragment("/") do
    {:top, nil, []}
  end

  defp parse_fragment("/" <> path = fragment) do
    {:pointer, fragment, parse_pointer(path)}
  end

  defp parse_fragment(anchor) do
    {:anchor, anchor, anchor}
  end

  defp parse_pointer(raw_docpath) do
    raw_docpath |> String.split("/") |> Enum.map(&parse_pointer_segment/1)
  end

  defp parse_pointer_segment(string) do
    case Integer.parse(string) do
      {int, ""} -> int
      _ -> unescape_json_pointer(string)
    end
  end

  defp unescape_json_pointer(str) do
    str
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
    |> URI.decode()
  end

  @spec escape_json_pointer(binary) :: binary
  def escape_json_pointer(str) do
    str
    |> String.replace("/", "~1")
    |> String.replace("~", "~0")
  end
end
