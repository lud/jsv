# Defining Schemas

This guide explains the different possible values to use as a schema with JSV.


## Schema sources

Schemas given as input to JSV can come from two sources:

* Schemas given directly to the `JSV.build/2` function. These are expected to be
  maps or booleans. JSV will not parse JSON strings.
* Schemas returned by resolvers. These should also be maps (but not booleans).
  The built-in resolvers will handle JSON deserialization automatically.

JSV is designed to work with raw schemas. Any map or boolean is a valid schema.
For instance, it is possible to directly use a schema from a file:

```elixir
root =
  "my-schema.json"
  |> File.read!()
  |> JSON.decode!()
  |> JSV.build()
```


## Schema formats

Schemas can be either booleans or maps. The `true` value is equivalent to an
empty JSON Schema `{}`, while `false` is a schema that will invalidate any
value. It is most often used as a sub-schema for `additionalProperties`.

Maps can define keys and values as binaries or atoms. The following schemas are
equivalent:

```elixir
%{type: :boolean}
%{type: "boolean"}
%{"type" => "boolean"}
%{"type" => :boolean} # You will rarely find this one in the wild!
```

This is because JSV will normalize the schemas before building a "root", the
base data structure for data validation.

Note that mixing keys is not recommended. In the following example, JSV will
build a schema that will successfully validate integers with a minimum of zero.
However, the choice for the maximum value is not made by JSV.

```elixir
%{:type => :integer, "minimum" => 0, "maximum" => 10, :maximum => 20}
```


## Struct schemas

Schemas can be used to define structs.

For instance, with this module definition schema:

```elixir
defmodule MyApp.UserSchema do
  import JSV

  defschema(%{
    type: :object,
    properties: %{
      name: %{type: :string, default: ""},
      age: %{type: :integer, default: 0}
    }
  })
end
```

A struct will be defined with the appropriate default values:

```elixir
iex> %MyApp.UserSchema{}
%MyApp.UserSchema{name: "", age: 0}
```

The module can be used as a schema to build a validator root and cast data to
the corresponding struct:

```elixir
iex> {:ok, root} = JSV.build(MyApp.UserSchema)
iex> data = %{"name" => "Alice"}
iex> JSV.validate(data, root)
{:ok, %MyApp.UserSchema{name: "Alice", age: 0}}
```

Casting to a struct can be disabled by passing `cast: false` into the
options of `JSV.validate/3`.

```elixir
iex> {:ok, root} = JSV.build(MyApp.UserSchema)
iex> data = %{"name" => "Alice", "extra" => "hello!"}
iex> JSV.validate(data, root, cast: false)
{:ok, %{"name" => "Alice", "extra" => "hello!"}}
```

The module can also be used in other schemas:

```elixir
%{
  type: :object,
  properties: %{
    name: %{type: :string},
    owner: MyApp.UserSchema
  }
}
```
