defmodule JSV.Schema.Helpers do
  alias JSV.Schema
  import JSV.Schema, only: [combine: 2, xcast: 2]
  import JSV.Schema.HelpersCompiler

  @moduledoc """
  Helpers to define schemas in plain Elixir code.
  """

  @schema_presets_doc """
  Schema presets are functions that take zero or more arguments and return
  predefined schemas. Those predefined schemas are _not_ `JSV.Schema` structs
  but raw maps.

  Each function has a second version with an additional `extra` argument that
  will be combined with the predefined schema using `JSV.Schema.combine/2`.

  Note that the `extra` attributes cannot override what is defined in the
  preset.

  ### Example

      %{
        properties: %{
          foo: integer(),
          bar: integer(description: "An actual bar", minimum: 10),
          baz: any_of([MyApp.Baz,MyApp.OldBaz], description: "Baz baz baz")
        }
      }
  """

  @moduledoc groups: [
               %{title: "Schema Presets", description: @schema_presets_doc}
             ]

  @type property_key :: atom | binary
  @type nested_schema :: JSV.native_schema()
  @type properties :: [{property_key, nested_schema}] | %{optional(property_key) => nested_schema}
  @type schema :: Schema.schema()
  @type extra :: Schema.attributes() | nil

  @doc """
  The Schema Description sigil.

  A sigil used to embed long texts in schemas descriptions. Replaces all
  combinations of whitespace by a single whitespace and trims the string.

  It does not support any modifier.

  Note that newlines are perfectly fine in schema descriptions, as they are
  simply encoded as `"\\n"`. This sigil is intended for schemas that need to be
  compressed because they are sent over the wire repeatedly (like in HTTP APIs
  or when working with LLMs).

  ### Example

      iex> ~SD\"""
      ...> This schema represents an elixir.
      ...>
      ...> An elixir is a potion with positive outcomes!
      ...> \"""
      "This schema represents an elixir. An elixir is a potion with positive outcomes!"
  """
  defmacro sigil_SD({:<<>>, _, [description]}, []) do
    formatted = description |> String.replace(~r{\s+}, " ") |> String.trim()

    quote do
      unquote(formatted)
    end
  end

  @doc """
  An alias for `JSV.Schema.combine/2`.

  ### Example

      iex> object(description: "a user")
      ...> ~> any_of([AdminSchema, CustomerSchema])
      ...> ~> properties(foo: integer())
      %{
        type: :object,
        description: "a user",
        properties: %{foo: %{type: :integer}},
        anyOf: [AdminSchema, CustomerSchema]
      }
  """
  defdelegate left ~> right, to: JSV.Schema, as: :combine

  defpreset :boolean, type: :boolean

  defpreset :integer, type: :integer
  defpreset :number, type: :number
  defpreset :pos_integer, type: :integer, minimum: 1
  defpreset :non_neg_integer, type: :integer, minimum: 0
  defpreset :neg_integer, type: :integer, maximum: -1

  @doc "Returns a JSON Schema with `allOf: schemas`."
  @doc group: "Schema Presets"
  @spec all_of([nested_schema], extra) :: schema
  def all_of(schemas, extra \\ nil) when is_list(schemas) do
    combine(extra, %{allOf: schemas})
  end

  @doc "Returns a JSON Schema with `anyOf: schemas`."
  @doc group: "Schema Presets"
  @spec any_of([nested_schema], extra) :: schema
  def any_of(schemas, extra \\ nil) when is_list(schemas) do
    combine(extra, %{anyOf: schemas})
  end

  @doc "Returns a JSON Schema with `oneOf: schemas`."
  @doc group: "Schema Presets"
  @spec one_of([nested_schema], extra) :: schema
  def one_of(schemas, extra \\ nil) when is_list(schemas) do
    combine(extra, %{oneOf: schemas})
  end

  @doc "Returns a schema with `type: :string` that casts strings to integers."
  @doc group: "Schema Presets"
  @spec string_to_integer(extra) :: schema
  def string_to_integer(extra \\ nil) do
    extra |> combine(%{type: :string}) |> xcast(JSV.Cast.string_to_integer())
  end

  @doc "Returns a schema with `type: :string` that casts strings to floats."
  @doc group: "Schema Presets"
  @spec string_to_float(extra) :: schema
  def string_to_float(extra \\ nil) do
    extra |> combine(%{type: :string}) |> xcast(JSV.Cast.string_to_float())
  end

  @doc "Returns a schema with `type: :string` that casts strings to numbers (integers or floats)."
  @doc group: "Schema Presets"
  @spec string_to_number(extra) :: schema
  def string_to_number(extra \\ nil) do
    extra |> combine(%{type: :string}) |> xcast(JSV.Cast.string_to_number())
  end

  @doc """
  Returns a schema with `type: :string` that casts `"true"` and `"false"` to
  booleans.
  """
  @doc group: "Schema Presets"
  @spec string_to_boolean(extra) :: schema
  def string_to_boolean(extra \\ nil) do
    extra |> combine(%{type: :string}) |> xcast(JSV.Cast.string_to_boolean())
  end

  @doc "Returns a schema with `type: :string` that casts strings to existing atoms."
  @doc group: "Schema Presets"
  @spec string_to_existing_atom(extra) :: schema
  def string_to_existing_atom(extra \\ nil) do
    extra |> combine(%{type: :string}) |> xcast(JSV.Cast.string_to_existing_atom())
  end

  @doc "Returns a schema with `type: :string` that casts strings to atoms."
  @doc group: "Schema Presets"
  @spec string_to_atom(extra) :: schema
  def string_to_atom(extra \\ nil) do
    extra |> combine(%{type: :string}) |> xcast(JSV.Cast.string_to_atom())
  end

  defpreset :string, type: :string
  defpreset :date, type: :string, format: :date
  defpreset :datetime, type: :string, format: :"date-time"
  defpreset :uri, type: :string, format: :uri
  defpreset :uuid, type: :string, format: :uuid
  defpreset :email, type: :string, format: :email
  defpreset :non_empty_string, type: :string, minLength: 1

  @doc "Returns a JSON Schema with `type: :array` and `items: item_schema`."
  @doc group: "Schema Presets"
  @spec array_of(nested_schema, extra) :: schema
  def array_of(item_schema, extra \\ nil) do
    combine(extra, %{type: :array, items: item_schema})
  end

  @doc """
  Does **not** set the `type: :string` on the schema. Use `string_of/2` for a
  shortcut.
  """
  @doc group: "Schema Presets"
  @spec format(atom | binary, extra) :: schema
  def format(format, extra \\ nil) when is_binary(format) when is_atom(format) do
    combine(extra, %{format: format})
  end

  @doc "Returns a JSON Schema with `type: :string` and `format: format`."
  @doc group: "Schema Presets"
  @spec string_of(atom | binary, extra) :: schema
  def string_of(format, extra \\ nil) when is_binary(format) when is_atom(format) do
    combine(extra, %{type: :string, format: format})
  end

  @doc """
  Note that in the JSON Schema specification, if the enum contains `1` then
  `1.0` is a valid value.
  """
  @doc group: "Schema Presets"
  @spec enum(list, extra) :: schema
  def enum(enum, extra \\ nil) when is_list(enum) do
    combine(extra, %{enum: enum})
  end

  @doc "Returns a JSON Schema with `const: const`."
  @doc group: "Schema Presets"
  @spec const(term, extra) :: schema
  def const(const, extra \\ nil) do
    combine(extra, %{const: const})
  end

  @doc """
  Accepts a list of atoms and returns a schema that validates  a string
  representation of one of the given atoms.

  On validation, a cast will be made to return the original atom value.

  This is useful when dealing with enums that are represented as atoms in the
  codebase, such as Oban job statuses or other Ecto enum types.

      iex> schema = props(status: string_enum_to_atom([:executing, :pending]))
      iex> root = JSV.build!(schema, atoms: true)
      iex> JSV.validate(%{"status" => "pending"}, root)
      {:ok, %{"status" => :pending}}

  > #### Does not support `nil` {: .warning}
  >
  > See `string_enum_to_atom_or_nil/2` for `nil` support.
  >
  > This function sets the `string` type on the schema. If `nil` is given in the
  > enum, the corresponding valid JSON value will be the `"nil"` string rather
  > than `null`.
  """
  @doc group: "Schema Presets"
  @spec string_enum_to_atom([atom], extra) :: schema
  def string_enum_to_atom(enum, extra \\ nil) when is_list(enum) do
    # We need to cast atoms to string, otherwise if `nil` is provided
    # it will be JSON-encoded as `nil` instead of `"null". But this
    # caster only accepts strings.
    extra
    |> combine(%{type: :string, enum: Enum.map(enum, &Atom.to_string/1)})
    |> xcast(JSV.Cast.string_to_atom())
  end

  @doc """
  Like `string_enum_to_atom/2` but also validates `null` JSON values. The `nil`
  atom should not be given in the atom list, except if you want to accept the
  `"nil"` JSON string and cast it to `nil`.
  """
  @doc group: "Schema Presets"
  @spec string_enum_to_atom_or_nil([atom], extra) :: schema
  def string_enum_to_atom_or_nil(enum, extra \\ nil) when is_list(enum) do
    extra
    |> combine(%{type: [:string, :null], enum: [nil | Enum.map(enum, &Atom.to_string/1)]})
    |> xcast(JSV.Cast.string_to_atom_or_nil())
  end

  @doc """
  See the `props/2` function that accepts properties as a first argument.
  """
  defpreset :object, type: :object

  @doc """
  Does **not** set the `type: :object` on the schema. Use `props/2` for a
  shortcut.

  Note that any preexisting schema properties are replaced.
  """
  @doc group: "Schema Presets"
  @spec properties(properties, extra) :: schema
  def properties(properties, extra \\ nil) when is_list(properties) when is_map(properties) do
    combine(extra, %{properties: Map.new(properties)})
  end

  @doc """
  Note that any preexisting schema properties are replaced.
  """
  @doc group: "Schema Presets"
  @spec props(properties, extra) :: schema
  def props(properties, extra \\ nil) when is_list(properties) when is_map(properties) do
    combine(extra, %{type: :object, properties: Map.new(properties)})
  end

  @doc """
  Object properties with atom keys.

  Like `props/2`, but on validation the defined properties are returned with
  atom keys instead of string keys. Additional properties (not listed in the
  schema) keep their string keys.

  Note that any preexisting schema properties are replaced.

  ### Example

      iex> schema = aprops(name: string(), age: integer())
      iex> root = JSV.build!(schema, atoms: true)
      iex> JSV.validate!(%{"name" => "Alice", "age" => 123}, root)
      %{name: "Alice", age: 123}

  """
  @doc group: "Schema Presets"
  @spec aprops(properties, extra) :: schema
  def aprops(properties, extra \\ nil) when is_list(properties) when is_map(properties) do
    extra
    |> combine(%{type: :object, properties: Map.new(properties)})
    |> xcast(JSV.Cast.atom_property_keys())
  end

  @doc """
  Required object properties with atom keys.

  Like `props/2`, but on validation the defined properties are returned with
  atom keys instead of string keys. Additional properties (not listed in the
  schema) keep their string keys.

  Note that any preexisting schema properties are replaced.

  ### Example

      iex> schema = aprops(name: string(), age: integer())
      iex> root = JSV.build!(schema, atoms: true)
      iex> JSV.validate!(%{"name" => "Alice", "age" => 123}, root)
      %{name: "Alice", age: 123}

  """
  @doc group: "Schema Presets"
  @spec arprops(properties, extra) :: schema
  def arprops(properties, extra \\ nil)
      when is_list(properties)
      when is_map(properties) do
    required =
      case properties do
        %{} -> Map.keys(properties)
        [_ | _] -> Enum.map(properties, fn {k, _} -> k end)
        [] -> []
      end

    extra
    |> combine(%{properties: Map.new(properties), required: required})
    |> xcast(JSV.Cast.atom_property_keys())
  end

  @doc """
  Returns a schema referencing the given `ref`.

  A struct-based schema module name is not a valid reference. Modules should be
  passed directly where a schema (and not a `$ref`) is expected.

  #### Example

  For instance to define a `user` property, this is valid:
  ```
  props(user: UserSchema)
  ```

  The following is invalid:
  ```
  # Do not do this
  props(user: ref(UserSchema))
  ```
  """
  @doc group: "Schema Presets"
  @spec ref(String.t(), extra) :: schema
  def ref(ref, extra \\ nil) do
    combine(extra, %{"$ref": ref})
  end

  @doc """
  Marks a schema as optional when using the keyword list syntax with
  `JSV.defschema/1` or `JSV.defschema/3`.

  This is useful for recursive module references where you want to avoid
  infinite nesting requirements. When used in property list syntax with
  `defschema`, the property will not be marked as required.

  ```
  defschema name: string(),
            parent: optional(MySelfReferencingModule)
  ```

  ### Skipping optional keys during JSON serialization

  **This is only applicable to schema defined with `JSV.defschema/3`**. The
  more generic macro `JSV.defschema/1` let you implement a full module so you
  must implement the protocols yourself, or use anyOf: null/sub schema for some
  properties.

  When encoding a struct to JSON, optional value (set as `nil` in the struct)
  are still rendered, which may be invalid if someone needs to validate the
  serialized value with the original schema. As the optional properties are not
  required, the `:nskip` option (for "normalization skip") with a constant value
  can be given. The value will not be serialized if it matches the value.

  ```
  defschema name: string(),
            parent: optional(MySelfReferencingModule, nskip: nil)
  ```
  """
  @spec optional(term) :: {:__optional__, term, keyword()}
  @spec optional(term, keyword()) :: {:__optional__, term, keyword()}
  def optional(schema, opts \\ []) do
    {:__optional__, schema, opts}
  end

  @doc """
  Makes a schema nullable by adding `:null` to the allowed types.

  ### Example

      iex> nullable(integer())
      %{type: [:integer, :null]}

      iex> nullable(%{type: :integer, anyOf: [%{minimum: 1}, %{maximum: -1}]})
      %{
        type: [:integer, :null],
        anyOf: [%{type: :null}, %{minimum: 1}, %{maximum: -1}]
      }

      iex> nullable(%{type: :integer, oneOf: [%{minimum: 1}, %{maximum: -1}]})
      %{
        type: [:integer, :null],
        oneOf: [%{type: :null}, %{minimum: 1}, %{maximum: -1}]
      }

  When given a schema module, wraps it in an `anyOf` that allows either the
  module's schema or null:

      iex> defmodule Position do
      ...>   use JSV.Schema
      ...>   defschema x: integer(), y: integer()
      ...> end
      iex> nullable(Position)
      %{anyOf: [%{type: :null}, Position]}

      iex> defmodule Point do
      ...>   def json_schema do
      ...>     %{
      ...>       "properties" => %{
      ...>         "x" => %{"type" => "integer"},
      ...>         "y" => %{"type" => "integer"}
      ...>       }
      ...>     }
      ...>   end
      ...> end
      iex> nullable(Point)
      %{anyOf: [%{type: :null}, Point]}
  """
  @spec nullable(map() | module()) :: map()
  def nullable(schema) when is_atom(schema) do
    if Schema.schema_module?(schema) do
      %{anyOf: [%{type: :null}, schema]}
    else
      raise ArgumentError,
            "nullable/1 expected a schema map or a schema module, got: #{inspect(schema)}"
    end
  end

  def nullable(schema) when is_map(schema) do
    Map.new(schema, fn
      {:enum, enum} when is_list(enum) -> {:enum, [nil | enum -- [nil]]}
      {:type, t} -> {:type, nullable_type(t)}
      {:anyOf, schemas} -> {:anyOf, nullable_list(schemas)}
      {:oneOf, schemas} -> {:oneOf, nullable_list(schemas)}
      other -> other
    end)
  end

  defp nullable_type(:null) do
    :null
  end

  defp nullable_type(t) when is_atom(t) do
    [t, :null]
  end

  defp nullable_type(t) when is_list(t) do
    [:null | t -- [:null]]
  end

  defp nullable_list(list) do
    [%{type: :null} | list]
  end
end
