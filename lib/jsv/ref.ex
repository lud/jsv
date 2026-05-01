defmodule JSV.Ref do
  alias __MODULE__
  alias JSV.RNS

  @moduledoc """
  Representation of a JSON Schema reference (`$ref` or `$dynamicRef`).
  """

  defstruct ns: nil, kind: nil, arg: nil, dynamic?: false

  @type t :: %__MODULE__{}
  @type ns :: binary | :root

  @doc """
  Creates a new reference from an URL, relative to the given namespace.

  If the URL is absolute and its namespace is different from the given
  namespace, returns an absolute URL.
  """
  @spec parse(binary, ns) :: {:ok, t} | {:error, term}
  def parse(url, current_ns) do
    do_parse(url, current_ns, false)
  end

  @doc """
  Raising version of the `parse/2` function.
  """
  @spec parse!(binary, ns) :: t
  def parse!(url, current_ns) do
    case parse(url, current_ns) do
      {:ok, ref} -> ref
      {:error, reason} -> raise ArgumentError, "could not parse $ref: #{inspect(url)}, got: #{inspect(reason)}"
    end
  end

  @doc """
  Like `parse/2` but flags the reference as dynamic.
  """
  @spec parse_dynamic(binary, ns) :: {:ok, t} | {:error, term}
  def parse_dynamic(url, current_ns) do
    do_parse(url, current_ns, true)
  end

  @doc """
  Raising version of the `parse_dynamic/2` function.
  """
  @spec parse_dynamic!(binary, ns) :: t
  def parse_dynamic!(url, current_ns) do
    case parse_dynamic(url, current_ns) do
      {:ok, ref} -> ref
      {:error, reason} -> raise ArgumentError, "could not parse $dynamicRef: #{inspect(url)}, got: #{inspect(reason)}"
    end
  end

  @doc """
  Creates a new pointer reference from a list of path segments.

  The segments can be strings or integers, representing the path components
  of a JSON pointer.

  ## Examples

      iex> JSV.Ref.pointer(["properties", "name"], :root)
      {:ok, %JSV.Ref{ns: :root, kind: :pointer, arg: ["properties", "name"], dynamic?: false}}

      iex> JSV.Ref.pointer(["items", 0], :root)
      {:ok, %JSV.Ref{ns: :root, kind: :pointer, arg: ["items", 0], dynamic?: false}}

  """
  @spec pointer([binary | integer], ns) :: {:ok, t}
  def pointer(segments, ns) when is_list(segments) do
    {:ok, pointer!(segments, ns)}
  end

  @doc """
  Creates a new pointer reference from a list of path segments.

  Raising version of the `pointer/2` function.
  """
  @spec pointer!([binary | integer], ns) :: t
  def pointer!(segments, ns) when is_list(segments) do
    %Ref{ns: ns, kind: :pointer, arg: segments, dynamic?: false}
  end

  defp do_parse(url, current_ns, dynamic?) do
    uri = URI.parse(url)
    {kind, arg} = parse_fragment(uri.fragment)

    dynamic? = dynamic? and kind == :anchor

    with {:ok, ns} <- RNS.derive(current_ns, url) do
      {:ok, %Ref{ns: ns, kind: kind, arg: arg, dynamic?: dynamic?}}
    end
  end

  defp parse_fragment(nil) do
    {:top, []}
  end

  defp parse_fragment("") do
    {:top, []}
  end

  defp parse_fragment("/") do
    {:top, []}
  end

  defp parse_fragment("/" <> path) do
    {:pointer, parse_pointer(path)}
  end

  defp parse_fragment(anchor) do
    {:anchor, anchor}
  end

  defp parse_pointer(raw_docpath) do
    raw_docpath |> String.split("/") |> Enum.map(&parse_pointer_segment/1)
  end

  defp parse_pointer_segment(string) do
    unescape_json_pointer(string)
  end

  defp unescape_json_pointer(str) do
    str
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
    |> URI.decode()
  end

  @doc """
  Encodes the given string as a JSON representation of a JSON pointer, that is
  with `~` as `~0` and `/` as `~1`.
  """
  @spec escape_json_pointer(binary | iodata()) :: binary
  def escape_json_pointer(str) when is_binary(str) do
    str
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end

  def escape_json_pointer(str) do
    str
    |> IO.iodata_to_binary()
    |> escape_json_pointer()
  end
end

defimpl Inspect, for: JSV.Ref do
  alias JSV.Ref

  # credo:disable-for-next-line Credo.Check.Readability.Specs
  def inspect(ref, opts) do
    do_inspect(ref, opts)
  end

  defp do_inspect(%Ref{dynamic?: true, kind: :anchor, ns: ns, arg: anchor}, _) do
    "JSV.Ref.parse_dynamic!(#{inspect("##{anchor}")}, #{inspect(ns)})"
  end

  defp do_inspect(%Ref{kind: :top, ns: ns}, _) do
    "JSV.Ref.parse!(\"\", #{inspect(ns)})"
  end

  defp do_inspect(%Ref{kind: :anchor, ns: ns, arg: anchor}, _) do
    "JSV.Ref.parse!(#{inspect("##{anchor}")}, #{inspect(ns)})"
  end

  defp do_inspect(%Ref{kind: :pointer, ns: ns, arg: path}, _) do
    "JSV.Ref.parse!(#{inspect(pointer_url(path))}, #{inspect(ns)})"
  end

  defp pointer_url(path) do
    IO.iodata_to_binary(["#/", Enum.map_intersperse(path, "/", &to_pointer_segment/1)])
  end

  defp to_pointer_segment(segment) when is_integer(segment) do
    segment
    |> Integer.to_string()
    |> to_pointer_segment()
  end

  defp to_pointer_segment(segment) when is_binary(segment) do
    segment
    |> Ref.escape_json_pointer()
    |> URI.encode(&URI.char_unreserved?/1)
  end
end

defimpl String.Chars, for: JSV.Ref do
  alias JSV.Ref

  # credo:disable-for-next-line Credo.Check.Readability.Specs
  def to_string(ref) do
    %Ref{ns: ns, kind: kind, arg: arg} = ref
    IO.iodata_to_binary([ns_to_prefix(ns), fragment_to_ref_suffix(kind, arg)])
  end

  defp ns_to_prefix(:root) do
    ""
  end

  defp ns_to_prefix(ns) when is_binary(ns) do
    ns
  end

  defp fragment_to_ref_suffix(:top, _) do
    ""
  end

  defp fragment_to_ref_suffix(:anchor, anchor) when is_binary(anchor) do
    ["#", anchor]
  end

  defp fragment_to_ref_suffix(:pointer, path) when is_list(path) do
    ["#/", Enum.map_intersperse(path, "/", &to_pointer_segment/1)]
  end

  defp to_pointer_segment(segment) when is_integer(segment) do
    segment
    |> Integer.to_string()
    |> to_pointer_segment()
  end

  defp to_pointer_segment(segment) when is_binary(segment) do
    segment
    |> Ref.escape_json_pointer()
    |> URI.encode(&URI.char_unreserved?/1)
  end
end
