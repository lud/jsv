defmodule JSV.Resolver.HttpcTest do
  alias JSV.Codec
  alias JSV.Resolver.Embedded
  alias JSV.Resolver.Httpc
  use ExUnit.Case, async: false
  use Patch

  doctest Httpc, tags: [:skip]

  test "will not resolve an URL if the prefix is not allowed" do
    assert {:error, {:restricted_url, _}} =
             Httpc.resolve("http://example.com/schema", allowed_prefixes: [])
  end

  @tag :skip
  test "will download from a remote endpoint" do
    # :inets, :ssl and :crypto are started by the tests or a common library ... so this
    # will always work.
    assert {:normal, %{"slideshow" => _}} =
             Httpc.resolve("https://httpbin.org/json",
               cache_dir: false,
               allowed_prefixes: ["https://httpbin.org/"]
             )
  end

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
end
