defmodule JSV.RNS do
  @moduledoc """

  A "namespace" for a schema ID or reference. In the JSV library, a namespace
  for a schema represents the document the schema belongs to. When it is an URL,
  it is the scheme, host and path, ignoring the query string and the fragment.

  That is basically a URI but with extra support for URNs (`urn:isbn:1234` is
  represented as `urn://isbn/1234`).
  """

  # TODO maybe do not use the URI module at all and implement a custom parser.

  @type t :: URI.t() | :root

  @doc """
  Parses the given URL or URN and returns an internal representation of its
  namespace.

  Also accepts `:root` for root schemas without `$id`.
  """
  @spec parse(binary | :root) :: t
  def parse(uri)

  def parse(string) when is_binary(string) do
    URI.parse(string)
  end

  def parse(:root) do
    :root
  end

  @doc """
  Returns a new string namespace by appending a relative path to a base
  namespace. If the relative is absolute or `:root`, returns the relative.
  """
  @spec derive(binary | :root, binary | :root) :: {:ok, binary | :roo} | {:error, term}
  def derive(base, relative) do
    base_rns = parse(base)
    relative_rns = parse(relative)

    with {:ok, merged} <- merge(base_rns, relative_rns) do
      {:ok, to_ns(merged)}
    end
  end

  defp merge(:root = base, %{host: nil, path: nil}) do
    {:ok, base}
  end

  defp merge(:root, %{scheme: scheme} = relative) when is_binary(scheme) do
    {:ok, relative}
  end

  defp merge(:root, relative) do
    {:error, {:no_derivable_root_ns, URI.to_string(relative)}}
  end

  defp merge(base, relative) do
    case relative do
      %URI{scheme: nil} ->
        case safe_uri_merge(base, relative) do
          {:ok, target} -> {:ok, target}
          {:error, _} = err -> err
        end

      %URI{scheme: _} ->
        {:ok, relative}
    end
  end

  # The URI module does not allow to merge URIs onto relative URIs. The problem
  # is that the URI module considers URIs without host as not valid absolute
  # URIs. The check is made on the host. For instance
  # `"urn:uuid:deadbeef-1234-00ff-ff00-4321feebdaed"` does not have a :host, so
  # it will fail. However it is allowed to merge fragments onto such URIs that
  # are non hierachical (does not have "//" at the start indicating a hierachy
  # of components such as //authorithy/path1/path2/).
  #
  # In this function we will check if the relative URI is only a fragment, and
  # if so, we will fake the :host and leading slash of the base URI to let the
  # URI module merge it.
  #
  # TODO this should be handled by the standard library though.
  defp safe_uri_merge(%{host: nil} = base_uri, relative_uri) do
    case relative_uri do
      %URI{
        port: nil,
        scheme: nil,
        path: nil,
        host: nil,
        userinfo: nil,
        query: nil,
        fragment: _fragment
      } ->
        # Enable this if we want to actually merge the URIs
        #
        #     {:ok, Map.put(base_uri, :fragment, fragment)}
        #
        # For now this is only used to generate an ns, to the fragment will be
        # discarded anyway
        {:ok, base_uri}

      _ ->
        {:error, {:invalid_uri_merge, base_uri, relative_uri}}
    end
  end

  defp safe_uri_merge(base_uri, relative_uri) do
    {:ok, URI.merge(base_uri, relative_uri)}
  end

  @doc """
  Returns the string value of the namespace, or `:root`.
  """
  @spec to_ns(t) :: binary | :root
  def to_ns(:root) do
    :root
  end

  def to_ns(uri) do
    to_string_no_fragment(uri)
  end

  defp to_string_no_fragment(%URI{} = uri) do
    String.Chars.URI.to_string(Map.put(uri, :fragment, nil))
  end
end
