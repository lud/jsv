defmodule JSV.Test.TestResolver do
  @mutex __MODULE__.Mutex
  @root_dir Path.join([File.cwd!(), "_build", "resolver-cache"])
  @suite_dir Path.join([File.cwd!(), "deps", "json_schema_test_suite", "remotes"])
  File.mkdir_p!(@root_dir)
  require Logger

  def resolve("http://localhost:1234/" <> _ = url) do
    # Logger.debug("Returning local file for #{url}")
    uri = URI.parse(url)
    return_local_file(uri.path)
  end

  def resolve("urn:uuid:feebdaed-ffff-0000-ffff-0000deadbeef") do
    return_local_file("urn-ref-string.json")
  end

  def resolve("http://example.com" <> _ = url) do
    raise "should not resolve example.com for #{url}"
  end

  def resolve("http" <> _ = url) do
    true = allow_host?(url)
    %{host: host, path: path, query: nil, fragment: frag} = URI.parse(url)
    true = frag in [nil, ""]
    path = [@root_dir, host | String.split(path, "/")] |> Path.join()

    # Prevent concurrent cache checks and fetches of the same resource.

    Mutex.with_lock(@mutex, {:fetch, host}, fn ->
      case File.read(path) do
        {:ok, json} -> Jason.decode(json)
        {:error, :enoent} -> fetch_and_write(url, path)
      end
    end)
  end

  def allow_host?("http://json-schema.org/" <> _) do
    true
  end

  def allow_host?("https://json-schema.org/" <> _) do
    true
  end

  def allow_host?(url) do
    raise "unallowed test resolver host: #{url}"
  end

  defp return_local_file(path) do
    full_path = Path.join(@suite_dir, path)

    case File.read(full_path) do
      {:ok, json} -> Jason.decode(json)
      {:error, :enoent} -> {:error, {:local_not_found, path}}
    end
  end

  defp fetch_and_write(url, path) do
    with {:ok, %{status: 200, body: json}} <- http_get(url),
         :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, data} <- Jason.decode(json),
         :ok <- File.write(path, json) do
      {:ok, data}
    end
  end

  defp http_get(url) do
    headers = []
    http_options = [ssl: ExSslOptions.eef_options()]

    url = String.to_charlist(url)
    IO.puts([IO.ANSI.yellow(), "GET ", url, IO.ANSI.reset()])
    http_result = :httpc.request(:get, {url, headers}, http_options, body_format: :binary)

    case http_result do
      {:ok, {{_, status, _}, _, body}} -> {:ok, %{status: status, body: body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def start_mutex do
    {:ok, _} = Mutex.start(name: @mutex)
  end
end
