defmodule JSV.Schema do
  alias JSV.Resolver.Internal
  import JSV.Schema.Defcompose

  @t_doc "`%#{inspect(__MODULE__)}{}` struct"

  @moduledoc """
  This module defines a struct where all the supported keywords of the JSON
  schema specification are defined as keys. Text editors that can predict the
  struct keys will make autocompletion available when writing schemas.

  ### Using in build

  The #{@t_doc} can be given to `JSV.build/2`:

      schema = %JSV.Schema{type: :integer}
      JSV.build(schema, options())

  Because Elixir structs always contain all their defined keys, writing a schema
  as `%JSV.Schema{type: :integer}` is actually defining the following:

      %JSV.Schema{
        type: :integer,
        "$id": nil
        additionalItems: nil,
        additionalProperties: nil,
        allOf: nil,
        anyOf: nil,
        contains: nil,
        # etc...
      }

  For that reason, when giving a #{@t_doc} to `JSV.build/2`, any `nil` value is
  ignored. The same behaviour can be defined for other struct by implementing
  the `JSV.Normalizer.Normalize` protocol. Mere maps will keep their `nil`
  values.

  Note that `JSV.build/2` does not require #{@t_doc}s, any map with binary or
  atom keys is accepted.

  This is also why the #{@t_doc} does not define the `const` keyword, because
  `nil` is a valid value for that keyword but there is no way to know if the
  value was omitted or explicitly defined as `nil`. To circumvent that you may
  use the `enum` keyword or just use a regular map instead of this module's
  struct:

      %#{inspect(__MODULE__)}{enum: [nil]}
      # OR
      %{const: nil}

  ### Functional helpers

  This module also exports a small range of utility functions to ease writing
  schemas in a functional way.

  This is mostly useful when generating schemas dynamically, or for shorthands.

  For instance, instead of writing the following:

      %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, description: "the name of the user", minLength: 1},
          age: %Schema{type: :integer, description: "the age of the user"}
        },
        required: [:name, :age]
      }

  One can write:

      %Schema{
        type: :object,
        properties: %{
          name: string(description: "the name of the user", minLength: 1),
          age: integer(description: "the age of the user")
        },
        required: [:name, :age]
      }

  This is also useful when building schemas dynamically, as the helpers are
  pipe-able one into another:

      new()
      |> props(
        name: string(description: "the name of the user", minLength: 1),
        age: integer(description: "the age of the user")
      )
      |> required([:name, :age])
  """

  @moduledoc groups: [
               %{
                 title: "Schema Definition Utilities",
                 description: """
                 Helper functions to define schemas or merge into a schema when
                 given as the first argument.

                 See `merge/2` for more information.
                 """
               },
               %{
                 title: "Schema Casts",
                 description: """
                 Built-in cast functions for JSON Schemas.

                 Functions in this section can be called on a schema to return a
                 new schema that will automatically cast the data to the
                 desired type upon validation.
                 """
               }
             ]

  @all_keys [
    :"$anchor",
    :"$comment",
    :"$defs",
    :"$dynamicAnchor",
    :"$dynamicRef",
    :"$id",
    :"$ref",
    :"$schema",
    :additionalItems,
    :additionalProperties,
    :allOf,
    :anyOf,
    :contains,
    :contentEncoding,
    :contentMediaType,
    :contentSchema,
    :default,
    :dependencies,
    :dependentRequired,
    :dependentSchemas,
    :deprecated,
    :description,
    :else,
    :enum,
    :examples,
    :exclusiveMaximum,
    :exclusiveMinimum,
    :format,
    :if,
    :items,
    :maxContains,
    :maximum,
    :maxItems,
    :maxLength,
    :maxProperties,
    :minContains,
    :minimum,
    :minItems,
    :minLength,
    :minProperties,
    :multipleOf,
    :not,
    :oneOf,
    :pattern,
    :patternProperties,
    :prefixItems,
    :properties,
    :propertyNames,
    :readOnly,
    :required,
    :then,
    :title,
    :type,
    :unevaluatedItems,
    :unevaluatedProperties,
    :uniqueItems,
    :writeOnly,

    # Internal keys
    :"jsv-cast"
  ]

  @derive {Inspect, optional: @all_keys}
  defstruct @all_keys

  @type t :: %__MODULE__{}
  @type schema_data :: %{optional(binary) => schema_data} | [schema_data] | number | binary | boolean | nil
  @type overrides :: map | [{atom | binary, term}]
  @type base :: map | [{atom | binary, term}] | struct | nil
  @type property_key :: atom | binary
  @type properties :: [{property_key, schema}] | %{optional(property_key) => schema}
  @type schema :: true | false | map

  @doc """
  Returns a new empty schema.
  """
  @spec new :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Returns a new schema with the given key/values.
  """
  @spec new(t | overrides) :: t
  def new(%__MODULE__{} = schema) do
    schema
  end

  def new(key_values) when is_list(key_values) when is_map(key_values) do
    struct!(__MODULE__, key_values)
  end

  @doc """
  Merges the given key/values into the base schema. The merge is shallow and
  will overwrite any pre-existing key.

  The resulting schema is always a map or a struct but the actual type depends
  on the given base. It follows the followng rules:

  * **When the base type is a map or a struct, it is preserved**
    - If the base is a #{@t_doc}, the `values` are merged in.
    - If the base is another struct, the `values` a merged in. It will fail if
      the struct does not define the overriden keys. No invalid struct is
      generated.
    - If the base is a mere map, it is **not** turned into a #{@t_doc} and the
      `values` are merged in.

  * **Otherwise the base is cast to a #{@t_doc}**
    - If the base is `nil`, the function returns a #{@t_doc} with the given
      `values`.
    - If the base is a keyword list, the list will be turned into a #{@t_doc}
    and then the `values` are merged in.

  ## Examples

      iex> JSV.Schema.merge(%JSV.Schema{description: "base"}, %{type: :integer})
      %JSV.Schema{description: "base", type: :integer}

      defmodule CustomSchemaStruct do
        defstruct [:type, :description]
      end

      iex> JSV.Schema.merge(%CustomSchemaStruct{description: "base"}, %{type: :integer})
      %CustomSchemaStruct{description: "base", type: :integer}

      iex> JSV.Schema.merge(%CustomSchemaStruct{description: "base"}, %{format: :date})
      ** (KeyError) struct CustomSchemaStruct does not accept key :format

      iex> JSV.Schema.merge(%{description: "base"}, %{type: :integer})
      %{description: "base", type: :integer}

      iex> JSV.Schema.merge(nil, %{type: :integer})
      %JSV.Schema{type: :integer}

      iex> JSV.Schema.merge([description: "base"], %{type: :integer})
      %JSV.Schema{description: "base", type: :integer}
  """
  @doc section: :schema_utilities
  @spec merge(base, overrides) :: schema
  def merge(nil, values) do
    new(values)
  end

  def merge(base, values) when is_list(base) do
    struct!(new(base), values)
  end

  def merge(%mod{} = base, values) do
    struct!(base, values)
  rescue
    e in KeyError ->
      reraise %{e | message: "struct #{inspect(mod)} does not accept key #{inspect(e.key)}"}, __STACKTRACE__
  end

  def merge(base, values) when is_map(base) do
    Enum.into(values, base)
  end

  @doc "Alias for `merge/2`."
  @deprecated "Use `merge/2`"
  @spec override(base, overrides) :: schema
  def override(base, values) do
    merge(base, values)
  end

  defcompose :boolean, type: :boolean

  defcompose :integer, type: :integer
  defcompose :number, type: :number
  defcompose :pos_integer, type: :integer, minimum: 1
  defcompose :non_neg_integer, type: :integer, minimum: 0
  defcompose :neg_integer, type: :integer, maximum: -1

  @doc """
  See `props/2` to define the properties as well.
  """
  defcompose :object, type: :object

  @doc """
  Does **not** set the `type: :array` on the schema. Use `array_of/2` for a
  shortcut.
  """
  defcompose :items, items: item_schema :: schema
  defcompose :array_of, type: :array, items: item_schema :: schema

  defcompose :string, type: :string
  defcompose :date, type: :string, format: :date
  defcompose :datetime, type: :string, format: :"date-time"
  defcompose :uri, type: :string, format: :uri
  defcompose :uuid, type: :string, format: :uuid
  defcompose :email, type: :string, format: :email
  defcompose :non_empty_string, type: :string, minLength: 1

  @doc """
  Does **not** set the `type: :string` on the schema. Use `string_of/2` for a
  shortcut.
  """
  defcompose :format, [format: format] when is_binary(format) when is_atom(format)
  defcompose :string_of, [type: :string, format: format] when is_binary(format) when is_atom(format)

  @doc """
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
  defcompose :ref, "$ref": ref :: String.t()

  @doc """
  Does **not** set the `type: :object` on the schema. Use `props/2` for a
  shortcut.
  """

  defcompose :properties,
             [
               properties: Map.new(properties) <- properties :: properties
             ]
             when is_list(properties)
             when is_map(properties)

  defcompose :props,
             [
               type: :object,
               properties: Map.new(properties) <- properties :: properties
             ]
             when is_list(properties)
             when is_map(properties)

  defcompose :all_of, [allOf: schemas :: [schema]] when is_list(schemas)
  defcompose :any_of, [anyOf: schemas :: [schema]] when is_list(schemas)
  defcompose :one_of, [oneOf: schemas :: [schema]] when is_list(schemas)

  @doc """
  Includes the cast function in a schema. The cast function must be given as a
  2-item list with:

  * A module, as atom or string
  * A tag, as atom, string or integer.

  Atom arguments will be converted to string.

  ### Examples

      iex> JSV.Schema.cast([MyApp.Cast, :a_cast_function])
      %JSV.Schema{"jsv-cast": ["Elixir.MyApp.Cast", "a_cast_function"]}

      iex> JSV.Schema.cast([MyApp.Cast, 1234])
      %JSV.Schema{"jsv-cast": ["Elixir.MyApp.Cast", 1234]}

      iex> JSV.Schema.cast(["some_erlang_module", "custom_tag"])
      %JSV.Schema{"jsv-cast": ["some_erlang_module", "custom_tag"]}
  """
  @doc sub_section: :schema_casters
  @spec cast(base, [atom | binary | integer, ...]) :: schema()
  def cast(base \\ nil, [mod, tag] = _mod_tag)
      when (is_atom(mod) or is_binary(mod)) and (is_atom(tag) or is_binary(tag) or is_integer(tag)) do
    merge(base, "jsv-cast": [to_string_if_atom(mod), to_string_if_atom(tag)])
  end

  defp to_string_if_atom(value) when is_atom(value) do
    Atom.to_string(value)
  end

  defp to_string_if_atom(value) do
    value
  end

  @doc sub_section: :schema_casters
  defcompose :string_to_integer, type: :string, "jsv-cast": JSV.Cast.string_to_integer()

  @doc sub_section: :schema_casters
  defcompose :string_to_float, type: :string, "jsv-cast": JSV.Cast.string_to_float()

  @doc sub_section: :schema_casters
  defcompose :string_to_number, type: :string, "jsv-cast": JSV.Cast.string_to_number()

  @doc sub_section: :schema_casters
  defcompose :string_to_boolean, type: :string, "jsv-cast": JSV.Cast.string_to_boolean()

  @doc sub_section: :schema_casters
  defcompose :string_to_existing_atom, type: :string, "jsv-cast": JSV.Cast.string_to_existing_atom()

  @doc sub_section: :schema_casters
  defcompose :string_to_atom, type: :string, "jsv-cast": JSV.Cast.string_to_atom()

  @doc """
  Accepts a list of atoms and validates that a given value is a string
  representation of one of the given atoms.

  On validation, a cast will be made to return the original atom value.

  This is useful when dealing with enums that are represented as atoms in the
  codebase, such as Oban job statuses or other Ecto enum types.

      iex> schema = JSV.Schema.props(status: JSV.Schema.string_to_atom_enum([:executing, :pending]))
      iex> root = JSV.build!(schema)
      iex> JSV.validate(%{"status" => "pending"}, root)
      {:ok, %{"status" => :pending}}

  > #### Does not support `nil` {: .warning}
  >
  > This function sets the `string` type on the schema. If `nil` is given in the
  > enum, the corresponding valid JSON value will be the `"nil"` string rather
  > than `null`
  """
  @doc sub_section: :schema_casters
  defcompose :string_to_atom_enum,
             [
               type: :string,
               # We need to cast atoms to string, otherwise if `nil` is provided
               # it will be JSON-encoded as `nil` instead of `"null". But this
               # caster only accepts strings.
               enum: Enum.map(enum, &Atom.to_string/1) <- enum :: [atom],
               "jsv-cast": JSV.Cast.string_to_atom()
             ]
             when is_list(enum)

  @doc """
  Defines a JSON Schema with `required: keys` or adds the given `keys` if the
  [base schema](JSV.Schema.html#merge/2) already has a `:required`
  definition.

  Existing required keys are preserved.

  ### Examples

      iex> JSV.Schema.required(%{}, [:a, :b])
      %{required: [:a, :b]}

      iex> JSV.Schema.required(%{required: nil}, [:a, :b])
      %{required: [:a, :b]}

      iex> JSV.Schema.required(%{required: [:c]}, [:a, :b])
      %{required: [:a, :b, :c]}

      iex> JSV.Schema.required(%{required: [:a]}, [:a])
      %{required: [:a, :a]}

  Use `merge/2` to replace existing required keys.

      iex> JSV.Schema.merge(%{required: [:a, :b, :c]}, required: [:x, :y, :z])
      %{required: [:x, :y, :z]}
  """
  @doc section: :schema_utilities
  @spec required(base, [atom | binary]) :: t
  def required(base \\ nil, key_or_keys)

  def required(nil, keys) when is_list(keys) do
    new(required: keys)
  end

  def required(base, keys) when is_list(keys) do
    case merge(base, []) do
      %{required: list} = cast_base when is_list(list) -> merge(cast_base, required: keys ++ list)
      cast_base -> merge(cast_base, required: keys)
    end
  end

  @doc """
  Normalizes a JSON schema with the help of `JSV.Normalizer.normalize/3` with
  the following customizations:

  * `JSV.Schema` structs pairs where the value is `nil` will be removed.
    `%JSV.Schema{type: :object, properties: nil, allOf: nil, ...}` becomes
    `%{"type" => "object"}`.
  * Modules names that export a schema will be converted to a raw schema with a
    reference to that module that can be resolved automatically by
    `JSV.Resolver.Internal`.
  * Other atoms will be checked to see if they correspond to a module name that
    exports a `schema/0` function.

  ### Examples

      defmodule Elixir.ASchemaExportingModule do
        def schema, do: %{}
      end

      iex> JSV.Schema.normalize(ASchemaExportingModule)
      %{"$ref" => "jsv:module:Elixir.ASchemaExportingModule"}

      defmodule AModuleWithoutExportedSchema do
        def hello, do: "world"
      end

      iex> JSV.Schema.normalize(AModuleWithoutExportedSchema)
      "Elixir.AModuleWithoutExportedSchema"
  """
  @spec normalize(term) :: %{optional(binary) => schema_data} | [schema_data] | number | binary | boolean | nil
  def normalize(term) do
    normalize_opts = [
      on_general_atom: fn atom, acc ->
        if schema_module?(atom) do
          {%{"$ref" => Internal.module_to_uri(atom)}, acc}
        else
          {Atom.to_string(atom), acc}
        end
      end
    ]

    {normal, _acc} = JSV.Normalizer.normalize(term, [], normalize_opts)

    normal
  end

  @common_atom_values [
    true,
    false,
    nil,
    #
    :array,
    :boolean,
    :enum,
    :integer,
    :null,
    :number,
    :object,
    :string
  ]

  @doc """
  Returns whether the given atom is a module with a `schema/0` exported
  function.
  """
  @spec schema_module?(atom) :: boolean
  def schema_module?(module) when module in @common_atom_values do
    false
  end

  def schema_module?(module) do
    Code.ensure_loaded?(module) && function_exported?(module, :schema, 0)
  end

  @doc """
  Returns the given `%#{inspect(__MODULE__)}{}` as a map without keys containing
  a `nil` value.
  """
  @spec to_map(t) :: %{optional(atom) => term}
  def to_map(%__MODULE__{} = schema) do
    schema
    |> Map.from_struct()
    |> Map.filter(fn {_, v} -> v != nil end)
  end

  defimpl JSV.Normalizer.Normalize do
    alias JSV.Helpers.MapExt

    def normalize(schema) do
      MapExt.from_struct_no_nils(schema)
    end
  end
end
