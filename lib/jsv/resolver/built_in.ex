defmodule JSV.Resolver.BuiltIn do
  alias JSV.Resolver.Cache
  require Logger

  @behaviour JSV.Resolver

  def resolve("http://" <> _ = url, opts) do
    allow_and_resolve(url, opts)
  end

  def resolve("https://" <> _ = url, opts) do
    allow_and_resolve(url, opts)
  end

  def resolve(url, _opts) do
    {:error, {:invalid_scheme, url}}
  end

  defp allow_and_resolve(url, opts) do
    allowed_prefixes = Keyword.fetch!(opts, :allowed_prefixes)
    cache_dir = Keyword.get_lazy(opts, :cache_dir, &default_cache_dir/0)

    if allow?(url, allowed_prefixes) do
      do_resolve(url, cache_dir)
    else
      {:error, {:restricted_url, url}}
    end
  end

  defp allow?(url, allowed_prefixes) do
    Enum.any?(allowed_prefixes, &String.starts_with?(url, &1))
  end

  defp do_resolve(url, cache_dir) do
    case URI.parse(url) do
      %{query: nil, fragment: frag} = uri when frag in [nil, ""] ->
        Cache.get_or_generate(Cache, {__MODULE__, url}, fn -> disk_cached_http_get(uri, url, cache_dir) end)

      _ ->
        {:error, {:unsupported_url, url}}
    end
  end

  defp disk_cached_http_get(uri, url, cache_dir) do
    %{scheme: scheme, host: host, path: path} = uri

    filename = "#{scheme}-#{host}/#{slugify(String.trim_leading(path, "/"))}-#{hash_url(url)}"

    path = Path.join(cache_dir, filename)

    case File.read(path) do
      {:ok, json} -> Jason.decode(json)
      {:error, :enoent} -> fetch_and_write(url, path)
    end
  end

  defp fetch_and_write(url, path) do
    :ok = ensure_cache_dir(Path.dirname(path))

    Logger.debug("Downloading JSON schema #{url}")

    with {:ok, %{status: 200, body: json}} <- http_get(url),
         {:ok, data} <- Jason.decode(json),
         :ok <- File.write(path, json) do
      {:ok, data}
    end
  end

  defp http_get(url) do
    headers = []
    # http_options = [ssl: ExSslOptions.eef_options()]
    http_options = []

    url = String.to_charlist(url)

    http_result = :httpc.request(:get, {url, headers}, http_options, body_format: :binary)

    case http_result do
      {:ok, {{_, status, _}, _, body}} -> {:ok, %{status: status, body: body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp slugify(<<c::utf8, rest::binary>>) when c in ?a..?z when c in ?A..?Z when c in ?0..?9 when c in [?-, ?_] do
    <<c::utf8>> <> slugify(rest)
  end

  defp slugify(<<_::utf8, rest::binary>>) do
    "-" <> slugify(rest)
  end

  defp slugify(<<>>) do
    ""
  end

  defp hash_url(url) do
    Base.encode32(:crypto.hash(:sha, url), padding: false)
  end

  def default_cache_dir do
    Path.join(System.tmp_dir!(), "jsv-resolver-http-cache")
  end

  defp ensure_cache_dir(dir) do
    case File.mkdir_p(dir) do
      :ok -> :ok
      {:error, reason} -> raise "could not create cache dir for #{inspect(__MODULE__)}: #{inspect(reason)}"
    end
  end
end
