# Resolvers

`JSV` may have to fetch other schemas when building a validation root. This
happens with `$schema`, `$ref`, or `$dynamicRef` properties pointing to an
absolute [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier).

In order to fetch those schemas, JSV requires a resolver. Resolvers are
user-defined, but JSV provides implementations for common use cases:

* `JSV.Resolver.Embedded` will resolve the most often used meta-schemas such as
  `https://json-schema.org/draft/2020-12/schema`.
* `JSV.Resolver.Internal` will resolve struct schemas given as module names as
  in the example just above.
* `JSV.Resolver.Httpc` will resolve schemas whose URI are `http` or `https`
  URLs. It uses the built-in Erlang HTTP client. While not packing many
  features, it does not enforce an HTTP client dependency in your application.


## Using resolvers

The `JSV.Resolver.Embedded` and `JSV.Resolver.Internal` are always enabled and
there is no need to declare them when building the root.

Other resolvers such as `JSV.Resolver.Httpc` or custom resolvers (see below)
need to be explicitly declared in the `:resolver` option of `JSV.build/2` or
`JSV.build!/2`:

```elixir
resolver = {JSV.Resolver.Httpc, allowed_prefixes: ["https://example.com/schemas/"]}
root = JSV.build!(schema, resolver: resolver)
```

Multiple resolvers can be passed as a list:

```elixir
root = JSV.build!(schema, resolver: [MyCustomResolver, MyOtherResolver])
```


## Custom resolvers

Users are encouraged to write their own resolver to support advanced use cases.

Custom resolvers are most often used for:

- Resolving URLs such as `my-company://some-id/` where the implementation knows
  a directory to retrieve that path from.
- Resolving `https://` URLs with custom network setups involving authentication,
  proxies, etc., or to use your HTTP library of choice.
- Returning hardcoded schemas directly from the codebase.
- Returning a schema dynamically, for instance depending on the `:prod` or
  `:test` environment.

To write a custom resolver, define a module that implements the `JSV.Resolver`
behaviour.


### A basic resolver implementation

```elixir
defmodule MyApp.SchemaResolver do
  @behaviour JSV.Resolver

  @user_schema %{type: :object, properties: %{name: %{type: :string}}}
  @website_schema %{type: :object, properties: %{url: %{type: :string}}}

  @impl true
  def resolve("myapp:user", _opts), do: {:ok, @user_schema}
  def resolve("myapp:website", _opts), do: {:ok, @website_schema}
  def resolve(_, _opts), do: {:error, :unknown}
end
```


### Resolving local files

The `JSV.Resolver.Local` helper can automatically load schemas from files and
directories. Schemas will be resolvable by their `$id` property.

```elixir
defmodule MyApp.LocalResolver do
  use JSV.Resolver.Local, source: [
    "priv/api/schemas",
    "priv/message-queue/schemas",
    "priv/special.file.json"
  ]
end
```

Make sure to check the documentation of `JSV.Resolver.Local` for more
information.


### Returning normalized schemas

If your resolver returns JSON data that is in normal form like this:

```elixir
%{
  "type" => "object",
  "additionalProperties" => false
}
```

Then the resolver implementation can return `{:normal, schema}` instead of
`{:ok, schema}` to skip the normalization step operated by JSV when building a
validation root.

The following form is _not_ normal and requires normalization:

```elixir
%{
  type: => :object,
  additionalProperties: => false
}
```

See `JSV.Normalizer.normalize/3` for more details.

## Resolvers form a chain

As mentioned before, the `JSV.Resolver.Embedded` and `JSV.Resolver.Internal` are
always enabled when calling `JSV.build/2`. This means that when calling the
following code:

```elixir
root = JSV.build(schema, resolver: [MyCustomResolver, MyOtherResolver])
```

The actual list of used resolvers is

* `MyCustomResolver`
* `MyOtherResolver`
* `JSV.Resolver.Embedded`
* `JSV.Resolver.Internal`

JSV will try each resolver in order until a successful response is returned, and
fail if _all_ of them return an error.

> #### Don't break the chain {: .warning}
>
> Make sure to define a catch-all clause for `resolve/2` in your implementation
> to return an `{:error, _}` tuple and allow other resolvers to be tried.
> Otherwise, a `FunctionClauseError` would be raised and the whole build would
> fail.

As all defined resolvers will be tried, there is no need call the built-in
resolvers from your own resolver before running some expensive or slow
computation (such as an HTTP call) because they will be called anyway.

```elixir
# You may do this

defmodule MyApp.SchemaResolver do
   def resolve("https://" <> _ = uri, _opts) do
    with {:error, {:not_embedded, _}} <- JSV.Resolver.Embedded.resolve(uri, []),
         {:ok, %{status: 200, body: schema}} <- MyApp.HttpClient.get(uri) do
      {:ok, schema}
    end
  end

  def resolve(_, _) do
    {:error, :unknown}
  end
end
```

The built-in resolvers are standard resolvers implementations and adhere to the
`JSV.Resolver` behaviour. That means that you can just pass them _before_ yours
as regular resolvers:

```elixir
# You should do this instead

root = JSV.build!(schema, resolvers: [JSV.Resolver.Embedded, MyApp.SchemaResolver])
```

The `JSV.Resolver.Embedded` resolver will only be called once.

There may be valid use cases for delegation. If you know of one, just let us
know!


