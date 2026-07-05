defmodule JSV.Resolver.Httpc do
  alias JSV.Resolver.Embedded
  import Bitwise
  require Logger

  @behaviour JSV.Resolver

  @default_max_body_size 10 * 1024 * 1024
  @default_request_timeout 30_000

  @moduledoc """
  A `JSV.Resolver` implementation that will fetch the schemas from the web with
  the help of the `:httpc` module.

  This resolver requires a list of allowed URL prefixes to download from. It
  also needs a proper JSON library to decode fetched schemas:

  * From Elixir 1.18, the `JSON` module is automatically available in the
    standard library.
  * JSV can use [Jason](https://hex.pm/packages/jason) if listed in your
    dependencies with the  `"~> 1.0"` requirement.

  Schemas known by the `JSV.Resolver.Embedded` will be fetched from that module
  instead of being fetched from the web. Allowed prefixes are not needed for
  those schemas.

  HTTPS downloads verify the server certificate and hostname against the
  operating system CA store, using `:public_key.cacerts_get/0`. Redirect
  responses fail the resolution with an error tuple; use the final URL directly
  in your schema references and allowed prefixes.

  ### Options

  This resolver supports the following options:

  - `:allowed_prefixes` - This option is mandatory and contains the allowed
    prefixes to download from. Each prefix must be a full URL with the scheme,
    host and at least the root path, like `https://example.com/`. A URL is
    allowed when it begins with one of the prefixes. A prefix is validated when
    it is matched against a URL, and raises an `ArgumentError` at that point if
    it is malformed.
  - `:cache_dir` - The path of a directory to cache downloaded resources. The
    default value can be retrieved with `default_cache_dir/0` and is a
    JSV-specific directory in the user cache, given by
    `:filename.basedir(:user_cache, "jsv")`, with a fallback on the system
    temporary directory when the user cache location is undefined. The option
    also accepts `false` to disable that cache. Cache directories are created
    with `0700` permissions and files are written atomically. Note that there
    is no cache expiration mechanism.
  - `:max_body_size` - The maximum size in bytes of a response body. Larger
    responses produce a `{:body_too_large, url}` error. Defaults to
    `#{@default_max_body_size}` (10 MiB).
  - `:request_timeout` - The request timeout in milliseconds. Defaults to
    `#{@default_request_timeout}`.

  ### Example

      iex> resolver_opts = [allowed_prefixes: ["https://www.schemastore.org/"], cache_dir: "_build/custom/dir"]
      iex> {:ok, _root} = JSV.build(%{"$ref": "https://www.schemastore.org/github-action.json"}, resolver: {JSV.Resolver.Httpc, resolver_opts})

  """

  @impl true
  def resolve(uri, opts) do
    case uri do
      "https://" <> _ -> try_embedded_or_fetch(uri, opts)
      "http://" <> _ -> try_embedded_or_fetch(uri, opts)
      other -> {:error, {:invalid_scheme, other}}
    end
  end

  defp try_embedded_or_fetch(url, opts) do
    case Embedded.resolve(url, []) do
      {:normal, schema} -> {:normal, schema}
      {:error, {:not_embedded, _}} -> allow_and_fetch(url, opts)
    end
  end

  defp allow_and_fetch(url, opts) do
    allowed_prefixes = Keyword.fetch!(opts, :allowed_prefixes)
    cache_dir = Keyword.get_lazy(opts, :cache_dir, &default_cache_dir/0)

    http_opts = %{
      max_body_size: Keyword.get(opts, :max_body_size, @default_max_body_size),
      timeout: Keyword.get(opts, :request_timeout, @default_request_timeout)
    }

    with :ok <- check_allowed(url, allowed_prefixes) do
      disk_cached_http_get(url, http_opts, make_disk_cache(url, cache_dir))
    end
  end

  defp check_allowed(url, allowed_prefixes) do
    if Enum.any?(allowed_prefixes, &prefix_allows?(&1, url)) do
      :ok
    else
      {:error, {:restricted_url, url}}
    end
  end

  # A validated prefix always contains the first "/" of the path, so a plain
  # string prefix match cannot be fooled by a crafted host like
  # "example.com.evil.com" or "example.com@evil.com".
  defp prefix_allows?(prefix, url) do
    validate_prefix!(prefix)
    String.starts_with?(url, prefix)
  end

  defp validate_prefix!(prefix) do
    case URI.parse(prefix) do
      %URI{scheme: scheme, host: host, path: "/" <> _} when scheme in ["http", "https"] and byte_size(host) > 0 ->
        :ok

      _ ->
        raise ArgumentError,
              "invalid allowed prefix #{inspect(prefix)} given to #{inspect(__MODULE__)}, " <>
                "prefixes must be http:// or https:// URLs with a host and a path, " <>
                ~s(for instance "https://example.com/")
    end
  end

  defp disk_cached_http_get(url, http_opts, disk_cache) do
    with {:ok, json} <- fetch_disk_or_http(url, http_opts, disk_cache),
         {:ok, schema} <- JSV.Codec.decode(json) do
      {:normal, schema}
    end
  end

  defp fetch_disk_or_http(url, http_opts, disk_cache) do
    case disk_cache.(:fetch) do
      {:ok, json} ->
        {:ok, json}

      {:error, :no_cache} ->
        case http_get(url, http_opts) do
          {:ok, json} ->
            :ok = disk_cache.({:write!, json})
            {:ok, json}

          {:error, _} = err ->
            err
        end
    end
  end

  defp http_get(url, http_opts) do
    %{timeout: timeout, max_body_size: max_body_size} = http_opts
    Logger.debug("Downloading JSON schema #{url}")

    headers = []
    http_options = [autoredirect: false, timeout: timeout] ++ transport_options(url)
    request_options = [sync: false, stream: :self, body_format: :binary]

    case :httpc.request(:get, {String.to_charlist(url), headers}, http_options, request_options) do
      {:ok, request_id} -> await_response(request_id, url, timeout, max_body_size)
      {:error, reason} -> {:error, reason}
    end
  end

  defp transport_options("https://" <> _) do
    [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 3,
        customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
      ]
    ]
  end

  defp transport_options(_) do
    []
  end

  defp await_response(request_id, url, timeout, max_body_size) do
    receive do
      {:http, {^request_id, :stream_start, headers}} ->
        case declared_content_length(headers) do
          length when is_integer(length) and length > max_body_size ->
            cancel_and_flush(request_id)
            {:error, {:body_too_large, url}}

          _ ->
            stream_body(request_id, url, timeout, max_body_size, [], 0)
        end

      {:http, {^request_id, {{_, 200, _}, _headers, body}}} when byte_size(body) <= max_body_size ->
        {:ok, body}

      {:http, {^request_id, {{_, 200, _}, _headers, _body}}} ->
        {:error, {:body_too_large, url}}

      {:http, {^request_id, {{_, status, _}, _headers, _body}}} ->
        {:error, {:http_status, status, url}}

      {:http, {^request_id, {:error, reason}}} ->
        {:error, reason}
    after
      timeout + 1000 ->
        cancel_and_flush(request_id)
        {:error, {:timeout, url}}
    end
  end

  defp stream_body(request_id, url, timeout, max_body_size, chunks, size) do
    receive do
      {:http, {^request_id, :stream, chunk}} ->
        size = size + byte_size(chunk)

        if size > max_body_size do
          cancel_and_flush(request_id)
          {:error, {:body_too_large, url}}
        else
          stream_body(request_id, url, timeout, max_body_size, [chunks, chunk], size)
        end

      {:http, {^request_id, :stream_end, _headers}} ->
        {:ok, IO.iodata_to_binary(chunks)}

      {:http, {^request_id, {:error, reason}}} ->
        {:error, reason}
    after
      timeout + 1000 ->
        cancel_and_flush(request_id)
        {:error, {:timeout, url}}
    end
  end

  defp declared_content_length(headers) do
    with {_, value} <- List.keyfind(headers, ~c"content-length", 0),
         {length, ""} <- Integer.parse(List.to_string(value)) do
      length
    else
      _ -> nil
    end
  end

  defp cancel_and_flush(request_id) do
    _ = :httpc.cancel_request(request_id)
    flush_messages(request_id)
  end

  defp flush_messages(request_id) do
    receive do
      {:http, {^request_id, _}} -> flush_messages(request_id)
      {:http, {^request_id, _, _}} -> flush_messages(request_id)
    after
      0 -> :ok
    end
  end

  defp make_disk_cache(_url, false) do
    fn
      :fetch -> {:error, :no_cache}
      {:write!, _} -> :ok
    end
  end

  defp make_disk_cache(url, cache_dir) when is_binary(cache_dir) do
    path = url_to_cache_path(url, cache_dir)
    :ok = ensure_cache_dir(cache_dir)
    :ok = ensure_cache_dir(Path.dirname(path))

    fn
      :fetch -> read_cache(path)
      {:write!, json} -> write_cache!(path, json)
    end
  end

  defp read_cache(path) do
    with {:ok, %File.Stat{type: :regular}} <- File.lstat(path),
         {:ok, json} <- File.read(path) do
      {:ok, json}
    else
      # A cache entry that is not a regular file (for instance a symlink) is
      # treated as a miss so the atomic write replaces it.
      {:ok, %File.Stat{}} -> {:error, :no_cache}
      {:error, :enoent} -> {:error, :no_cache}
      # For other disk errors we better raise, the cache directory is
      # misconfigured
      {:error, _} -> File.read!(path)
    end
  end

  defp write_cache!(path, json) do
    tmp_path = "#{path}.#{Base.encode32(:crypto.strong_rand_bytes(10), padding: false)}.tmp"
    File.write!(tmp_path, json, [:exclusive])

    case File.rename(tmp_path, path) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = File.rm(tmp_path)
        raise "could not write cache file #{inspect(path)} for #{inspect(__MODULE__)}: #{inspect(reason)}"
    end
  end

  @doc false
  @spec url_to_cache_path(binary, binary) :: binary
  def url_to_cache_path(url, cache_dir) do
    %{scheme: scheme, host: host, path: path} = URI.parse(url)
    sub_dir = Path.join(cache_dir, "#{scheme}-#{host}")
    filename = "#{slugify(String.trim_leading(path, "/"))}-#{hash_url(url)}.json"

    Path.join(sub_dir, filename)
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

  @doc """
  Returns the default directory used by the disk-based cache, a JSV-specific
  subdirectory of the user cache directory given by `:filename.basedir/2`.

  When the user cache directory is undefined, typically in minimal production
  environments where the `HOME` environment variable is not set, the returned
  directory is based on `System.tmp_dir!/0`.
  """
  @spec default_cache_dir :: binary
  def default_cache_dir do
    base =
      try do
        :filename.basedir(:user_cache, "jsv")
      catch
        # basedir requires HOME or XDG_CACHE_HOME to be defined
        :error, _ -> Path.join(System.tmp_dir!(), "jsv")
      end

    Path.join(base, "resolver-http-cache")
  end

  defp ensure_cache_dir(dir) do
    # The directories are created once per machine, so an already private
    # directory skips the mkdir/chmod calls on subsequent cache accesses.
    case File.stat(dir) do
      {:ok, %File.Stat{type: :directory, mode: mode}} when band(mode, 0o777) == 0o700 -> :ok
      _ -> create_cache_dir(dir)
    end
  end

  defp create_cache_dir(dir) do
    with :ok <- File.mkdir_p(dir),
         :ok <- File.chmod(dir, 0o700) do
      :ok
    else
      {:error, reason} ->
        raise "could not create cache dir #{inspect(dir)} for #{inspect(__MODULE__)}: #{inspect(reason)}"
    end
  end
end
