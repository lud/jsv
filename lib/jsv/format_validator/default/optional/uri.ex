require JSV.FormatValidator.Default.Optional

if JSV.FormatValidator.Default.Optional.mod_exists?(AbnfParsec) do
  defmodule JSV.FormatValidator.Default.Optional.URI do
    @moduledoc false
    @external_resource "priv/uri.abnf"

    use AbnfParsec,
      abnf_file: "priv/uri.abnf",
      unbox: [],
      ignore: []

    @spec parse_uri(binary) :: {:ok, URI.t()} | {:error, term}
    def parse_uri(data) do
      case uri(data) do
        {:ok, _, "", _, _, _} -> {:ok, URI.parse(data)}
        _ -> {:error, :invalid_URI}
      end
    end

    @spec parse_uri_reference(binary) :: {:ok, URI.t()} | {:error, term}
    def parse_uri_reference(data) do
      case uri_reference(data) do
        {:ok, _, "", _, _, _} -> {:ok, URI.parse(data)}
        _ -> {:error, :invalid_URI_reference}
      end
    end
  end
else
  defmodule JSV.FormatValidator.Default.Optional.URI do
    @moduledoc false
    @spec parse_uri(binary) :: {:ok, URI.t()} | {:error, term}
    def parse_uri(data) do
      case URI.parse(data) do
        %{scheme: nil} -> {:error, :no_uri_scheme}
        %{host: nil} -> {:error, :no_uri_host}
        uri -> {:ok, uri}
      end
    end

    @spec parse_uri_reference(binary) :: {:ok, URI.t()} | {:error, term}
    def parse_uri_reference(data) do
      case URI.parse(data) do
        %{host: nil, path: path, fragment: frag, query: q} = uri
        when is_binary(path)
        when is_binary(frag)
        when is_binary(q) ->
          {:ok, uri}

        %{host: "", path: path, fragment: frag, query: q} = uri
        when is_binary(path)
        when is_binary(frag)
        when is_binary(q) ->
          {:ok, uri}

        %{host: nil} ->
          {:error, :no_uri_host}

        %{host: ""} ->
          {:error, :no_uri_host}

        uri ->
          {:ok, uri}
      end
    end
  end
end
