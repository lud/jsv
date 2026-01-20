# JSV

<!-- rdmx :badges
    hexpm         : "jsv?color=4e2a8e"
    github_action : "lud/jsv/elixir.yaml?label=CI&branch=main"
    license       : jsv
    -->
[![hex.pm Version](https://img.shields.io/hexpm/v/jsv?color=4e2a8e)](https://hex.pm/packages/jsv)
[![Build Status](https://img.shields.io/github/actions/workflow/status/lud/jsv/elixir.yaml?label=CI&branch=main)](https://github.com/lud/jsv/actions/workflows/elixir.yaml?query=branch%3Amain)
[![License](https://img.shields.io/hexpm/l/jsv.svg)](https://hex.pm/packages/jsv)
<!-- rdmx /:badges -->

**JSV** is a JSON Schema validator for Elixir, designed for modern applications.
It provides full compliance with the latest JSON Schema specifications while
offering a seamless, Elixir-native developer experience.

## Key Features

- **Full Specification Compliance**: 100% support for **Draft 2020-12**
  (including `$dynamicRef`, `$dynamicAnchor`, and all vocabularies) and **Draft
  7**.
- **High Performance**: Schemas can be pre-compiled into an optimized internal
  representation. Build your validation roots at compile-time for **near-zero
  runtime overhead**.
- **Elixir-Native Schemas**: Use `defschema` to define schemas as Elixir
  modules. Supports automatic casting to **Elixir structs** with default values.
- **Advanced Casting & Transformation**:
  - Built-in support for casting to `Date`, `DateTime`, `Duration`, and
    `Decimal`.
  - Extensible casting system using the `jsv-cast` keyword and `defcast` macros.
- **Extensible Resolution**: Fetch remote schemas via HTTP or resolve them from
  local files and directories using custom or built-in resolvers.
- **Flexible Workflows**: Supports schemas as atoms or binaries, from Elixir
  code, JSON files, or the network. JSV supports many ways to work with schemas.
- **Extensible Vocabularies**: Thanks to features of Draft 2020-12, custom
  meta-schemas with custom schema keywords are supported out of the box.
- **Functional Builder API**: Compose schemas dynamically using a functional
  API.
- **Rich Error Handling**: Detailed validation errors that can be easily
  normalized into JSON-compatible structures for API responses.
- **Complete support in [Oaskit](https://github.com/lud/oaskit)**: Oaskit is an
  OpenAPI 3.1 validator for Phoenix and is entirely built on JSV.

## Documentation

[Comprehensive guides and API documentation are available on hexdocs.pm](https://hexdocs.pm/jsv/).

## Supported Dialects

JSV supports 100% of features from Draft 2020-12 and Draft 7 as verified by the
[JSON Schema Compliance Test Suite](https://bowtie.report/).

* [![Draft 2020-12](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Felixir-jsv%2Fcompliance%2Fdraft2020-12.json)](https://bowtie.report/#/implementations/elixir-jsv)
* [![Draft 7](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Felixir-jsv%2Fcompliance%2Fdraft7.json)](https://bowtie.report/#/implementations/elixir-jsv)

## Installation

Add `jsv` to your `mix.exs`:

<!-- rdmx :app_dep vsn:$app_vsn -->
```elixir
def deps do
  [
    {:jsv, "~> 0.16"},
  ]
end
```
<!-- rdmx /:app_dep -->

### Optional Dependencies

JSV integrates with popular Elixir libraries to provide enhanced functionality:

```elixir
def deps do
  [
    # JSV Supports Decimal and will validate Decimal structs as numbers.
    {:decimal, "~> 2.0"},

    # Required for resolving schemas via HTTP on Elixir < 1.18.
    {:jason, "~> 1.0"}, # OR {:poison, "~> 6.0"}
  ]
end
```

## Usage

### Simple Validation

<!-- rdmx :section format:true name:"simple-validation" -->
```elixir
schema = %{
  type: :object,
  properties: %{
    name: %{type: :string}
  },
  required: [:name]
}

root = JSV.build!(schema)

case JSV.validate(%{"name" => "Alice"}, root) do
  # %{"name" => "Alice"}
  {:ok, data} -> IO.inspect(data)
  {:error, err} -> IO.inspect(JSV.normalize_error(err))
end
```
<!-- rdmx /:section -->

### Module-Based Schemas

Define your business objects and validation logic in one place:
<!-- rdmx :section format:true name:"module-based" -->
```elixir
defmodule MyApp.User do
  use JSV.Schema

  defschema %{
    type: :object,
    properties: %{
      name: string(minLength: 1),
      age: integer(minimum: 0, default: 18)
    },
    required: [:name]
  }
end

# Build at compile-time for maximum performance
root = JSV.build!(MyApp.User)

# Casting to structs is enabled by default
%MyApp.User{name: "Alice", age: 18} = JSV.validate!(%{"name" => "Alice"}, root)
```
<!-- rdmx /:section -->

### Pydantic style modules

<!-- rdmx :section format:true name:"pydantic" -->
```elixir
use JSV.Schema

defschema MyApp.Data.Food,
          ~SD"""
          A Tasty dish, hopefully
          """,
          name: string(),
          origin: string()

defschema MyApp.Data.Profile,
          ~SD"""
          Information about a user profile
          """,
          name: string(),
          birthdate: optional(date()),
          favorite_food: MyApp.Data.Food

defschema MyApp.Data.User,
          ~SD"""
          System user information
          """,
          profile: MyApp.Data.Profile,
          role: string_enum_to_atom([:admin, :writer, :reader])

data = %{
  "profile" => %{
    "name" => "Alice",
    "birthdate" => "1994-01-08",
    "favorite_food" => %{
      "name" => "Pad Thai",
      "origin" => "Thailand"
    }
  },
  "role" => "admin"
}

root = JSV.build!(MyApp.Data.User, formats: true)
JSV.validate!(data, root, cast_formats: true)
```
<!-- rdmx /:section -->

With this simple module form you can define many struct schemas in a compact
way. The code above will cast the data (and the birthdate as well):

<!-- rdmx :eval section:pydantic  -->
```elixir
%MyApp.Data.User{
  profile: %MyApp.Data.Profile{
    birthdate: ~D[1994-01-08],
    favorite_food: %MyApp.Data.Food{name: "Pad Thai", origin: "Thailand"},
    name: "Alice"
  },
  role: :admin
}
```
<!-- rdmx /:eval -->

## Contributing

Please ensure your changes include thorough tests and follow the existing
documentation style.

## License

JSV is released under the [MIT License](LICENSE).
