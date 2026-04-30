# API Changes in JSV 0.9

JSV 0.9 introduces significant changes to the schema building API. While these
changes are designed to improve the long-term maintainability and usability of
the library, they do deprecate some existing functions. This guide explains the
changes, their rationale, and how to migrate your code.

## Overview of Changes

The main changes in JSV 0.9 are:

1. **Deprecation of the old composition API**: Functions returning predefined
   schemas in the `JSV.Schema` module like `integer/0` or `all_of/1` are now
   deprecated.
2. **Introduction of the composer**: Deprecated functions have been copied to
   `JSV.Schema.Composer` for backward compatibility.
3. **New preset functions**: A new `JSV.Schema.Helpers` module provides helper
   functions that are not composable but rather accept other schema attributes
   as the last argument. They return maps instead of `%JSV.Struct{}` schemas in
   all cases.
4. **Enhanced developer experience**: `use JSV.Schema` now imports all necessary
   functions to define schemas in plain Elixir code.

## The Old Composition API and Its Limitations

The previous API allowed for a fluent, pipeline-based approach to schema building but with too many quirks.

<!-- rdmx :section name:old_api format:true -->
```elixir
import JSV.Schema

schema =
  %Schema{}
  |> object()
  |> properties(%{
    age: integer(description: "The age"),
    name: string(),
    role:
      JSV.Schema.string_to_atom_enum(
        %{description: "The user role"},
        [:admin, :author, :editor]
      )
  })
  |> required([:age, :name])
```
<!-- rdmx /:section -->

While this approach looked elegant, it had several practical limitations:

1. **Unnecessary abstraction**: If you already know the structure of your
   schema, there's no need to pay the cost for merging schemas on every function
   call.
2. **Awkward argument order**: Functions like
   `JSV.Schema.Composer.string_to_atom_enum/2` required the base schema as the
   first argument, making composition cumbersome.
3. **Overriding composability**: Merging a schema multiple times could lead to
   overwrite previoulsy defined attributes.
4. **Unclear cast to struct**: The composition API is designed to work aroun
   `JSV.Schema.merge/2` that follows complicated rules regarding the base schema
   to merge into. It will keep maps as-is but will transform `nil` or keyword
   lists into a `%JSV.Schema{}` struct. This struct has always been designed to
   support autocompletion only but the compisition API enforces usage of this
   struct.


## The New Approach

### Direct Schema Definition

First, it has awlays been possible to define schemas statically. While more
verbose, it maps directly to the actual schema that is being defined and allows
to work with a single shape in mind.

<!-- rdmx :section name:no_funs format:true -->
```elixir
schema = %{
  type: :object,
  properties: %{
    age: %{type: :integer, description: "The age"},
    name: %{type: :string}
  },
  required: [:age, :name]
}
```
<!-- rdmx /:section -->

This approach is more explicit and performant, and doesn't require intermediate
pipeline steps when the final structure is known. No function calls means no
unexpected attributes.

### New Helper Functions with Improved API

The new `JSV.Schema.Helpers` module provides functions with a more intuitive
argument order.

We also took the liberty to change some function names like
`string_enum_to_atom` instead of `string_to_atom_enum`.

<!-- rdmx :section name:enum_example format:true -->
```elixir
schema = %{
  properties: %{
    age: integer(description: "The age"),
    name: string(),
    role:
      JSV.Schema.Helpers.string_enum_to_atom(
        [:admin, :author, :editor],
        description: "Some description"
      )
  }
}
```
<!-- rdmx /:section -->

The key improvement is that the primary argument comes first (the enum values in
this example), and additional attributes are provided as a list or map at the
end.

### Helpers do not return `JSV.Schema` structs

As visible above, helpers that do not take any primary argument look the same in
both APIs. While there is no visible change in the calls, there is an important
difference:

**This new API does not enforce creation of a `%JSV.Schema{}` struct** and will return bare maps instead. This allows to work with user-defined schema vocabularies using keywords that are now known in the struct.

So `integer(description: "some int")` will now return:

```elixir
%{type: :integer, description: "some int"}
```

Where the composition API would return:

```elixir
%JSV.Schema{type: :integer, description: "some int"}
```

### Composing with the new API

We suggest to simply use `Map.put/3` and `Map.merge/2` to build schemas
dynamically. It's less obscure and allows you to build your own helpers on top
of it.

A new `JSV.Schema.Helpers.~>/2` operator is available and brings back the composition API on top of the new helpers:

<!-- rdmx :section name:new_op format:true -->
```elixir
object(description: "a user")
~> any_of([AdminSchema, CustomerSchema])
~> properties(foo: integer())
```
<!-- rdmx /:section -->

## A new `use` macro to define schemas.

You can now import all necessary schema-defining functions with a single `use`
statement.

This will import macros (`JSV.defschema/1`, `JSV.defcast/{1,2,3}`) from `JSV`
and the new preset functions including the `JSV.Schema.Helpers.sigil_SD/2`
sigil.

<!-- rdmx :section name:use_example format:true -->
```elixir
defmodule MySchemas do
  use JSV.Schema

  defschema %{
    type: :object,
    description: ~SD"""
    This description spans multiple lines for readability.

    But the sigil will make it a oneliner.
    """,
    properties: %{
      id: integer(minimum: 1),
      name: string(minLength: 1),
      email: string(format: "email"),
      role: string_enum_to_atom([:admin, :user, :guest])
    },
    required: [:id, :name, :email, :role]
  }
end
```
<!-- rdmx /:section -->

## Future Considerations

### Backward Compatibility Timeline

- **`JSV.Schema.Composer`**: This module is maintained for backward compatibility only. No new functions will be added to it in future versions.
- **`JSV.Schema.Helpers`**: This is the new home for helper functions and will continue to grow with new presets and utilities.


