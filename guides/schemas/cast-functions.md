# Custom Cast Functions

JSV provides a mechanism to declare a cast function into a schema, to be called
once the validation is successful. This is the same mechanism used to cast
struct-schemas to Elixir structs.

This guide describes how to use a custom function in your schemas.

> **Migrating from v0.18?** See the
> [API changes in v0.19](../dev-log/002.api-changes-v0.19.md) for a summary of
> what changed and how to update your code.


## JSV's cast system

JSV stores the cast information in the JSON schemas under the `x-jsv-cast`
extension keyword. There is no central registry of cast functions, so any
library you use can define its own JSV casts without needing you to copy their
mapping, registry or whatever in your configuration.

The `x-jsv-cast` value is a list of _casters_. Each caster is either a string
(a resolvable module name) or a list whose first element is the module name
string, followed by arguments.

```json
{
  "description": "an existing Elixir atom",
  "type": "string",
  "x-jsv-cast": [["Elixir.MyApp.Schemas.Cast", "existing_atom"]]
}
```

This solution has multiple advantages:

* No configuration.
* Schemas remain fully declarative. The information about casting is collocated
  with other validation keywords such as `type`, `format`, `properties`, _etc_.
* Schemas are portable as JSV does not need additional configuration to know
  what code to call. Although, we use a module name so the module needs to be
  available in the Elixir runtime when data is validated.
* Schema reviewers can know that a schema uses a cast without needing to look
  elsewhere.
* Cast functions can be referenced into multiple schemas, they are not tied to a
  particular struct or schema-map defined in one place. You can also define them
  in generic schemas referenced with `$ref` or `$dynamicRef`.
* Multiple casts can be chained on a single schema and are applied in order.
* Cast functions can receive extra arguments from the schema.

There are some drawbacks as well:

* The `x-jsv-cast` information needs to be JSON-serializable, so modules are
  referenced as strings, and arguments can only be simple JSON data.
* Module names are leaked into the schemas. If this is not acceptable, you can
  declare a generic "Cast" module in your application and dispatch manually from
  there. Sometimes just cleaning the schemas before making them public is enough
  too.
* Refactoring can be harder. In general, you will not write the content of
  `x-jsv-cast` by hand but rather use our helper functions. Refactoring will be
  the same as with regular code.
* Indirection for the cast functions is required. See the security concerns
  below.


## Security concerns

In the previous example, `"existing_atom"` is a "tag" argument, and not a
function name that JSV would call blindly. Otherwise, if your app is processing
third-party schemas, a `["Elixir.System", "stop"]` or worse would be very bad.

For that reason, cast functions need to be enabled by developers by defining the
`__jsv__/1` callback.

This is an internal callback, not documented by a behaviour, but security is
important and it is worth explaining the mechanism here. The `__jsv__/1`
callback is generated automatically when you use the `defcast` macro.

When evaluating `["Elixir.System", "stop"]`, JSV will call `System.__jsv__({:cast,
["stop"]})` at schema build time. This function does not exist and JSV will catch that
error, refusing to build the schema.

The only way for that function to exist is if you define it in your own code.
While you could compile a custom Elixir version with a `__jsv__/1` function in
the `System` module, there are only so many reasons to do that.

But that applies to your modules as well. Only you can define the `__jsv__/1`
function in your modules.

Unresolved casts fail at build time, before any data is ever validated.

While this requires a few extra lines of code, we think it's a simple-enough
solution to prevent undesirable remote code execution.


## Defining cast functions

Cast functions are functions that return a generic result tuple:
- `{:ok, transformed_data}` for successful transformations.
- `{:error, reason}` when the transformation fails.

As described in the security section above, JSV needs the target module to
export a `__jsv__/1` callback that resolves the cast at build time. JSV supports
strings and integers as tag arguments.

To define cast functions, use the `defcast` macro (available via `use JSV.Schema`
or `import JSV`).


### Basic usage of `defcast`

The following module expects a string and returns the value in upper case:

```elixir
defmodule MyApp.Schemas.Cast do
  use JSV.Schema

  defcast to_uppercase(data) do
    {:ok, String.upcase(data)}
  end
end
```

This will define the `to_uppercase/1` function that will evaluate the body as
any regular function:

```elixir
MyApp.Schemas.Cast.to_uppercase("hello")
# => {:ok, "HELLO"}
```

It will also define a `to_uppercase/0` helper that returns the caster wire form
to include in a schema. The default tag of a cast is the function name, as a
string:

```elixir
MyApp.Schemas.Cast.to_uppercase()
# => ["Elixir.MyApp.Schemas.Cast", "to_uppercase"]
```

And finally, it will define the appropriate `__jsv__/1` callback so JSV can
resolve the cast at build time.

Use `JSV.Schema.xcast/2` to add the cast to a schema:

```elixir
schema = JSV.Schema.string() |> JSV.Schema.xcast(MyApp.Schemas.Cast.to_uppercase())
# => %{type: :string, "x-jsv-cast": [["Elixir.MyApp.Schemas.Cast", "to_uppercase"]]}

root = JSV.build!(schema)
JSV.validate("hello", root)
# => {:ok, "HELLO"}
```


### Cast functions with arguments

Cast functions can accept extra arguments from the schema. Define the function
with an `args` parameter (arity 2) or with `args` and `vctx` (arity 3):

```elixir
defmodule MyApp.Schemas.Cast do
  use JSV.Schema

  defcast append_suffix(data, args) do
    [suffix] = args
    {:ok, data <> suffix}
  end
end
```

When a handler accepts arguments, its helper takes an argument list:

```elixir
MyApp.Schemas.Cast.append_suffix(["!"])
# => ["Elixir.MyApp.Schemas.Cast", "append_suffix", "!"]
```

Use it in a schema:

```elixir
schema = JSV.Schema.string() |> JSV.Schema.xcast(MyApp.Schemas.Cast.append_suffix(["!"]))

root = JSV.build!(schema)
JSV.validate("hello", root)
# => {:ok, "hello!"}
```

Arguments must be JSON-encodable data.


### Using a custom tag

Custom tags can be given as the first argument of `defcast`:

```elixir
# Using a string tag
defcast "my_custom_tag", to_uppercase(data) do
  {:ok, String.upcase(data)}
end

# Using an integer tag
defcast ?u, to_uppercase(data) do
  {:ok, data}
end
```


### Exception handling

The `rescue`, `catch` and `after` blocks are supported:

```elixir
defcast safe_to_atom(data) do
  {:ok, String.to_existing_atom(data)}
rescue
  ArgumentError -> {:error, :unknown_atom}
end
```


### Referring to existing functions

Guards with the `when` keyword are not supported. But it is possible to refer to
an existing local function instead of defining the body directly.

The referred function must be defined with `def` (`defp` is not supported).

```elixir
defmodule MyApp.Schemas.Cast do
  use JSV.Schema

  # Pass the local function name as a single argument.
  defcast :to_upper

  # Custom tags are supported too
  defcast "custom_tag", :to_upper
  defcast ?u, :to_upper

  # The function needs to be defined in the module with `def`.
  def to_upper(data) when is_binary(data), do: {:ok, String.upcase(data)}
  def to_upper(data), do: {:error, :expected_string}
end
```


## Multicasting

Multiple casts can be declared on a single schema. They are applied in order. Each cast
receives the output of the previous one. If any cast fails, the chain stops.

```elixir
schema =
  JSV.Schema.string()
  |> JSV.Schema.xcast(MyApp.Cast.to_uppercase())
  |> JSV.Schema.xcast(MyApp.Cast.append_suffix(["!"]))

root = JSV.build!(schema)
JSV.validate("hello", root)
# => {:ok, "HELLO!"}
```


## Error Normalization

To return custom errors from your functions, you can optionally define the
`format_error/3` function that will receive the cast arguments (including the
tag), the `reason` and the validated data.

This will be called when JSV errors are normalized to be JSON-encodable.

<!-- rdmx :section name:example_error format:true -->
```elixir
defmodule MyApp.Schemas.Cast do
  use JSV.Schema

  defcast safe_to_atom(data) do
    {:ok, String.to_existing_atom(data)}
  rescue
    ArgumentError -> {:error, :unknown_atom}
  end

  def format_error(["safe_to_atom"], :unknown_atom, data) do
    "could not cast to existing atom: #{inspect(data)}"
  end
end

schema = JSV.Schema.Helpers.string() |> JSV.Schema.xcast(MyApp.Schemas.Cast.safe_to_atom())

root = JSV.build!(schema)
{:error, err} = JSV.validate("some string", root)
JSV.normalize_error(err)
```
<!-- rdmx /:section -->

The code above gives the following normalized error:

<!-- rdmx :eval section:example_error  -->
```elixir
%{
  details: [
    %{
      errors: [
        %{
          kind: :cast,
          message: "could not cast to existing atom: \"some string\""
        }
      ],
      evaluationPath: "#",
      instanceLocation: "#",
      schemaLocation: "#",
      valid: false
    }
  ],
  valid: false
}
```
<!-- rdmx /:eval -->
