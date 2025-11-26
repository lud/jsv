# Custom Cast Functions

JSV provides a mechanism to declare a cast function into a schema, to be called
once the validation is successful. This is the same mechanism used to cast
struct-schemas to Elixir structs.

This guide describes how to use a custom function in your schemas.


## JSV's cast system

JSV stores the cast information in the JSON schemas. There is no central
registry of cast functions, so any library you use can define its own JSV casts
without needing you to copy their mapping, registry or whatever in your
configuration.

That information is stored under the `x-jsv-cast` custom schema keyword as an
array containing a module name (as string) and a custom "tag".

```json
{
  "description": "an existing Elixir atom",
  "type": "string",
  "x-jsv-cast": ["Elixir.MyApp.Schemas.Cast", "existing_atom"]
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

There are some drawbacks as well:

* The `x-jsv-cast` information needs to be JSON-serializable, so modules are
  referenced as strings, and custom tags to identify the cast function can only
  be simple data. Currently JSV only accepts strings or integers.
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

In the previous example, `"existing_atom"` is a "tag", and not a function name
that JSV would call blindly. Otherwise, if your app is processing third-party
schemas, a `["Elixir.System", "stop"]` or worse would be very bad.

For that reason, cast functions need to be enabled by developers by defining the
`__jsv__/2` function.

This is an internal callback, not documented by a behaviour, but security is
important and it is worth explaining the mechanism here. The `__jsv__/2`
function is rather defined by using the `JSV.defcast/1` macro that is documented.

When evaluating `["Elixir.System", "stop"]`, JSV will indeed call the `System`
module. It will call `System.__jsv__("stop", data)` with the data under
validation. This function does not exist and JSV will catch that error.

The only way for that function to exist is if you define it in your own code.
While you could compile a custom Elixir version with a `__jsv__/2` function in
the `System` module, there are only so many reasons to do that.

But that applies to your modules as well. Only you can define the `__jsv__/2`
function in your modules.

While this requires a few extra lines of code, we think it's a simple-enough
solution to prevent undesirable remote code execution.


## Defining cast functions

Cast functions are functions that return a generic result tuple:
- `{:ok, transformed_data}` for successful transformations.
- `{:error, reason}` when the transformation fails.

As described in the security section above, JSV needs a tag to identify the
function to call with the data. JSV supports strings and integers as tags.

To define such functions, the `JSV.defcast/1`, `JSV.defcast/2` or
`JSV.defcast/3` macros should be used.


### Basic usage of `defcast`

The following module expects a string and returns the value in upper case:

```elixir
defmodule MyApp.Schemas.Cast do
  import JSV

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

It will also define the `to_uppercase/0` function that returns the cast
information to include in a schema. As you can see, the default tag of a cast is
the function name, as string.

```elixir
MyApp.Schemas.Cast.to_uppercase()
# => ["Elixir.MyApp.Schemas.Cast", "to_uppercase"]
```

And finally, it will define the appropriate `__jsv__/2` function to be used in a
schema:

```elixir
schema = JSV.Schema.string() |> JSV.Schema.with_cast(MyApp.Schemas.Cast.to_uppercase())
# => %JSV.Schema{
#      type: :string,
#      "x-jsv-cast": ["Elixir.MyApp.Schemas.Cast", "to_uppercase"]
#    }

root = JSV.build!(schema)
JSV.validate("hello", root)
# => {:ok, "HELLO"}
```


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


### Referring to Existing Functions

Guards with the `when` keyword are not supported at the moment. But it is
possible to call a local function instead of defining it directly.

Unfortunately, this does not export the 0-arity function to quickly define the
cast in schemas.

```elixir
# Pass the local function name as a single argument.
defcast :to_upper

# Custom tags are supported too
defcast "custom_tag", :to_upper
defcast ?u, :to_upper

# The function needs to be
# defined in the module as `def` or `defp`.
def to_upper(data) when is_binary(data), do: {:ok, String.upcase(data)}
def to_upper(data), do: {:error, :expected_string}

# Helper to reference the cast in schemas. This function does not need to
# exist, it is always possible to add this directly in a schema.
def to_upper do
  [to_string(__MODULE__), "to_upper"]
end
```


## Error Normalization

To return custom errors from your functions, you can optionally define the
`format_error/3` function that will receive the tag, the `reason` and the
validated data.

This will be called when JSV errors are normalized to be JSON-encodable.

<!-- rdmx :section name:example_error format:true -->
```elixir
defmodule MyApp.Schemas.Cast do
  import JSV

  defcast safe_to_atom(data) do
    {:ok, String.to_existing_atom(data)}
  rescue
    ArgumentError -> {:error, :unknown_atom}
  end

  def format_error("safe_to_atom", :unknown_atom, data) do
    "could not cast to existing atom: #{inspect(data)}"
  end
end

schema = JSV.Schema.Helpers.string() |> JSV.Schema.with_cast(MyApp.Schemas.Cast.safe_to_atom())

root = JSV.build!(schema)
{:error, err} = JSV.validate("some string", root)
JSV.normalize_error(err)
```
<!-- rdmx /:section -->

The code above gies the following normalized error:

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
