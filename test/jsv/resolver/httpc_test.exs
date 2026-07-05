defmodule JSV.Resolver.HttpcTest do
  alias JSV.Codec
  alias JSV.Resolver.Embedded
  alias JSV.Resolver.Httpc
  import Bitwise
  use ExUnit.Case, async: false
  use Patch

  @moduletag :capture_log

  doctest Httpc, tags: [:httpc_live]

  test "will not resolve an URL if the prefix is not allowed" do
    assert {:error, {:restricted_url, _}} =
             Httpc.resolve("http://example.com/schema", allowed_prefixes: [])
  end

  @tag :httpc_live
  test "will download from a remote endpoint" do
    # :inets, :ssl and :crypto are started by the tests or a common library ... so this
    # will always work.
    assert {:normal, %{"$schema" => _, "title" => "Schema for .prettierrc"}} =
             Httpc.resolve("https://www.schemastore.org/prettierrc.json",
               cache_dir: false,
               allowed_prefixes: ["https://www.schemastore.org/"]
             )
  end

  test "uses the embedded resolver for well known URIs resolver" do
    patch(Embedded, :resolve, fn uri, opts -> {:normal, %{"uri_called" => uri, "opts_called" => opts}} end)

    assert {:normal,
            %{
              # The URL should be given to the Embedded resolver
              "uri_called" => "https://json-schema.org/draft/2020-12/schema",
              # Options should not be forwarded
              "opts_called" => []
            }} ==
             Httpc.resolve("https://json-schema.org/draft/2020-12/schema",
               cache_dir: false,

               # The prefix is not needed
               allowed_prefixes: []
             )
  end

  describe "allow-list matching" do
    test "rejects host suffix and userinfo tricks" do
      # The prefix host must match the URL host exactly. Appending the allowed
      # host as a subdomain or as userinfo must not grant access.
      prefixes = ["https://example.com/"]

      assert {:error, {:restricted_url, _}} =
               Httpc.resolve("https://example.com.evil.com/schema.json",
                 allowed_prefixes: prefixes,
                 cache_dir: false
               )

      assert {:error, {:restricted_url, _}} =
               Httpc.resolve("https://example.com@evil.com/schema.json",
                 allowed_prefixes: prefixes,
                 cache_dir: false
               )
    end

    test "rejects a different port" do
      assert {:error, {:restricted_url, _}} =
               Httpc.resolve("https://example.com:8443/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false
               )
    end

    test "rejects a different scheme" do
      assert {:error, {:restricted_url, _}} =
               Httpc.resolve("http://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false
               )
    end

    test "rejects paths outside of the prefix path" do
      assert {:error, {:restricted_url, _}} =
               Httpc.resolve("https://example.com/private/schema.json",
                 allowed_prefixes: ["https://example.com/schemas/"],
                 cache_dir: false
               )
    end

    test "accepts a URL under the prefix path" do
      mock_complete_response(200, Codec.encode!(%{"type" => "integer"}))

      assert {:normal, %{"type" => "integer"}} =
               Httpc.resolve("https://example.com/schemas/some/schema.json",
                 allowed_prefixes: ["https://example.com/schemas/"],
                 cache_dir: false
               )
    end

    test "matching is byte-exact, host case differences are restricted" do
      assert {:error, {:restricted_url, _}} =
               Httpc.resolve("https://EXAMPLE.com/schemas/some/schema.json",
                 allowed_prefixes: ["https://example.com/schemas/"],
                 cache_dir: false
               )
    end

    test "raises on a prefix without a path" do
      assert_raise ArgumentError, ~r{"https://example\.com"}, fn ->
        Httpc.resolve("https://example.com/schema.json",
          allowed_prefixes: ["https://example.com"],
          cache_dir: false
        )
      end
    end

    test "prefixes are validated lazily" do
      # An invalid prefix is accepted in the configuration as long as it is not
      # matched against a URL. Here the first prefix matches so the second one
      # is never examined.
      mock_complete_response(200, Codec.encode!(%{"type" => "integer"}))

      assert {:normal, %{"type" => "integer"}} =
               Httpc.resolve("https://example.com/schemas/some/schema.json",
                 allowed_prefixes: ["https://example.com/schemas/", "https://no-path-prefix.com"],
                 cache_dir: false
               )
    end
  end

  describe "http request hardening" do
    test "redirects are refused" do
      # A 302 from an allowed host must not be followed, it is returned as an
      # http error. The autoredirect option must be disabled.
      test_pid = self()

      patch(:httpc, :request, fn :get, {_url, []}, http_options, _request_options ->
        send(test_pid, {:http_options, http_options})
        request_id = make_ref()

        send(
          test_pid,
          {:http, {request_id, {{~c"HTTP/1.1", 302, ~c"Found"}, [{~c"location", ~c"http://evil.internal/"}], ""}}}
        )

        {:ok, request_id}
      end)

      assert {:error, {:http_status, 302, _}} =
               Httpc.resolve("https://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false
               )

      assert_received {:http_options, http_options}
      refute Keyword.fetch!(http_options, :autoredirect)
    end

    test "https requests enable TLS peer verification" do
      mock_complete_response(200, Codec.encode!(%{}))

      assert {:normal, %{}} =
               Httpc.resolve("https://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false
               )

      assert_received {:http_options, http_options}
      ssl_opts = Keyword.fetch!(http_options, :ssl)
      assert :verify_peer == Keyword.fetch!(ssl_opts, :verify)
      assert [_ | _] = Keyword.fetch!(ssl_opts, :cacerts)
      assert [match_fun: _] = Keyword.fetch!(ssl_opts, :customize_hostname_check)
    end

    test "rejects a response with an oversized content-length" do
      test_pid = self()
      patch(:httpc, :cancel_request, fn _ -> :ok end)

      patch(:httpc, :request, fn :get, {_url, []}, _http_options, _request_options ->
        request_id = make_ref()
        send(test_pid, {:http, {request_id, :stream_start, [{~c"content-length", ~c"999999999999"}]}})
        {:ok, request_id}
      end)

      assert {:error, {:body_too_large, "https://example.com/schema.json"}} =
               Httpc.resolve("https://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false
               )
    end

    test "rejects a streamed body over the size limit" do
      test_pid = self()
      patch(:httpc, :cancel_request, fn _ -> :ok end)

      patch(:httpc, :request, fn :get, {_url, []}, _http_options, _request_options ->
        request_id = make_ref()
        send(test_pid, {:http, {request_id, :stream_start, []}})
        send(test_pid, {:http, {request_id, :stream, :binary.copy(<<0>>, 100)}})
        send(test_pid, {:http, {request_id, :stream, :binary.copy(<<0>>, 100)}})
        send(test_pid, {:http, {request_id, :stream_end, []}})
        {:ok, request_id}
      end)

      assert {:error, {:body_too_large, _}} =
               Httpc.resolve("https://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false,
                 max_body_size: 150
               )

      # The pending stream messages are flushed after cancellation
      refute_received {:http, _}
    end

    test "times out when no response is delivered" do
      patch(:httpc, :cancel_request, fn _ -> :ok end)

      patch(:httpc, :request, fn :get, {_url, []}, _http_options, _request_options ->
        {:ok, make_ref()}
      end)

      assert {:error, {:timeout, "https://example.com/schema.json"}} =
               Httpc.resolve("https://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false,
                 request_timeout: 50
               )
    end

    test "assembles a streamed body from chunks" do
      json = Codec.encode!(%{"title" => "streamed"})
      mock_streamed_response(chunk_binary(json, 3))

      assert {:normal, %{"title" => "streamed"}} =
               Httpc.resolve("https://example.com/schema.json",
                 allowed_prefixes: ["https://example.com/"],
                 cache_dir: false
               )
    end
  end

  describe "disk cache" do
    test "will use a directory cache" do
      url = "http://some-host/some/path"
      unique_id = System.system_time(:microsecond)
      cached_schema = %{"id" => "jsv://test/#{unique_id}"}

      # Define a cache directory for the test that we will give to the resolver
      cache_dir = Briefly.create!(directory: true, prefix: "jsv")

      # The Httpc module conveniently allows the test to know the cache path from
      # the URL in advance
      cached_path = Httpc.url_to_cache_path(url, cache_dir)

      # Prefill the cache. Cache is stored as plain json, not http responses
      # objects.
      cached_json = Codec.encode!(cached_schema)
      :ok = File.mkdir_p!(Path.dirname(cached_path))
      :ok = File.write!(cached_path, cached_json)

      # If the cache exists, it is returned
      assert {:normal, ^cached_schema} = Httpc.resolve(url, allowed_prefixes: [url], cache_dir: cache_dir)
    end

    test "writes cache files atomically in a private directory" do
      url = "http://some-host/some/schema"
      schema = %{"id" => "jsv://test/#{System.system_time(:microsecond)}"}
      json = Codec.encode!(schema)
      mock_complete_response(200, json)

      cache_dir = Briefly.create!(directory: true, prefix: "jsv")
      cached_path = Httpc.url_to_cache_path(url, cache_dir)

      assert {:normal, ^schema} = Httpc.resolve(url, allowed_prefixes: [url], cache_dir: cache_dir)

      # The response body is cached at the expected path, with no leftover
      # temporary file
      assert json == File.read!(cached_path)
      assert [] == Path.wildcard(Path.join(Path.dirname(cached_path), "*.tmp"))

      # Cache directories are private to the user
      assert 0o700 == band(File.stat!(cache_dir).mode, 0o777)
      assert 0o700 == band(File.stat!(Path.dirname(cached_path)).mode, 0o777)
    end

    test "a symlinked cache entry is ignored and replaced" do
      # A symlink planted at the cache path must not be read nor followed on
      # write. The resolver fetches the resource again and replaces the entry
      # with a regular file.
      url = "http://some-host/some/schema"
      schema = %{"id" => "jsv://test/#{System.system_time(:microsecond)}"}
      json = Codec.encode!(schema)
      mock_complete_response(200, json)

      cache_dir = Briefly.create!(directory: true, prefix: "jsv")
      cached_path = Httpc.url_to_cache_path(url, cache_dir)
      :ok = File.mkdir_p!(Path.dirname(cached_path))

      target = Path.join(cache_dir, "attacker-target.json")
      :ok = File.write!(target, Codec.encode!(%{"id" => "jsv://attacker"}))
      :ok = File.ln_s!(target, cached_path)

      assert {:normal, ^schema} = Httpc.resolve(url, allowed_prefixes: [url], cache_dir: cache_dir)

      # The symlink was replaced by a regular file and the target is untouched
      assert {:ok, %File.Stat{type: :regular}} = File.lstat(cached_path)
      assert %{"id" => "jsv://attacker"} == Codec.decode!(File.read!(target))
    end
  end

  # Patches :httpc.request to deliver a complete (non-streamed) response, as
  # :httpc does for non-200 statuses, and reports the http options to the test.
  defp mock_complete_response(status, body) do
    test_pid = self()

    patch(:httpc, :request, fn :get, {_url, []}, http_options, _request_options ->
      send(test_pid, {:http_options, http_options})
      request_id = make_ref()
      send(test_pid, {:http, {request_id, {{~c"HTTP/1.1", status, ~c"OK"}, [], body}}})
      {:ok, request_id}
    end)
  end

  # Patches :httpc.request to deliver a 200 response streamed as chunks.
  defp mock_streamed_response(chunks) do
    test_pid = self()

    patch(:httpc, :request, fn :get, {_url, []}, _http_options, _request_options ->
      request_id = make_ref()
      send(test_pid, {:http, {request_id, :stream_start, []}})
      Enum.each(chunks, &send(test_pid, {:http, {request_id, :stream, &1}}))
      send(test_pid, {:http, {request_id, :stream_end, []}})
      {:ok, request_id}
    end)
  end

  defp chunk_binary(bin, size) when byte_size(bin) <= size do
    [bin]
  end

  defp chunk_binary(bin, size) do
    <<chunk::binary-size(^size), rest::binary>> = bin
    [chunk | chunk_binary(rest, size)]
  end
end
