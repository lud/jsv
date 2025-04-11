defmodule JSV.Schema.Defcompose do
  @moduledoc false

  defguard is_literal(v) when is_atom(v) or is_integer(v) or (is_tuple(v) and is_list(elem(v, 2)))

  defp extract_guard(args_or_guarded) do
    case args_or_guarded do
      {:when, _meta, [args, guard]} -> {guard, args}
      args -> {true, args}
    end
  end

  defp expand_args(args, env) do
    Enum.map(args, fn {prop, value} ->
      value = Macro.expand(value, env)

      if Macro.quoted_literal?(value) do
        {:const, prop, value}
      else
        expand_expression(prop, value)
      end
    end)
  end

  defp expand_expression(prop, value) do
    case value do
      {:<-, _, [expr, value]} ->
        {bind, typespec} = extract_typespec(value)
        {:var, prop, bind, typespec, expr}

      value ->
        {bind, typespec} = extract_typespec(value)
        {:var, prop, bind, typespec, bind}
    end
  end

  defp extract_typespec(value) do
    case value do
      {:"::", _, [bind, typespec]} -> {bind, typespec}
      bind -> {bind, {:term, [], nil}}
    end
  end

  defmacro defcompose(fun, args_or_guarded) do
    {guard, args} = extract_guard(args_or_guarded)

    args = expand_args(args, __CALLER__)

    schema_props =
      Enum.map(args, fn
        {:const, prop, const} -> {prop, const}
        {:var, prop, _bind, _typespec, expr} -> {prop, expr}
      end)

    bindings =
      Enum.flat_map(args, fn
        {:const, _prop, _const} -> []
        {:var, _prop, bind, _typespec, _expr} -> [bind]
      end)

    typespecs =
      Enum.flat_map(args, fn
        {:const, _prop, _const} -> []
        {:var, _prop, _bind, typespec, _expr} -> [typespec]
      end)

    args_doc =
      Enum.map(args, fn
        {:const, prop, const} -> {prop, {:const, const}}
        {:var, prop, bind, _typespec, _expr} -> {prop, {:var, elem(bind, 0)}}
      end)

    # Start of quote

    quote location: :keep do
      doc_custom =
        case Module.get_attribute(__MODULE__, :doc) do
          {_, text} when is_binary(text) -> ["\n\n", text]
          _ -> ""
        end

      doc_schema_props =
        unquote(args_doc)
        |> Enum.map(fn
          {prop, {:const, const}} -> "`#{prop}: #{inspect(const)}`"
          {prop, {:var, var}} -> "`#{prop}: #{var}`"
        end)
        |> :lists.reverse()
        |> case do
          [last | [_ | _] = prev] ->
            prev
            |> Enum.intersperse(", ")
            |> :lists.reverse([" and ", last])

          [single] ->
            [single]
        end

      @doc """
      Overrides the [base schema](JSV.Schema.html#override/2) with #{doc_schema_props}.#{doc_custom}
      """
      @doc section: :schema_utilities
      @spec unquote(fun)(base, unquote_splicing(typespecs)) :: schema
      def unquote(fun)(base \\ nil, unquote_splicing(bindings)) when unquote(guard) do
        override(base, unquote(schema_props))
      end
    end
  end
end

defmodule JSV.Schema do
  alias JSV.Resolver.Internal
  import JSV.Schema.Defcompose

  @moduledoc """
  This module defines a struct where all the supported keywords of the JSON
  schema specification are defined as keys. Text editors that can predict the
  struct keys will make autocompletion available when writing schemas.

  ### Using in build

  The `#{inspect(__MODULE__)}` struct can be given to `JSV.build/2`:

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

  For that reason, when giving a `#{inspect(__MODULE__)}` struct to
  `JSV.build/2`, any `nil` value is ignored. This is not the case with other
  strucs or maps.

  Note that `JSV.build/2` does not require `#{inspect(__MODULE__)}` structs, any
  map with binary or atom keys is accepted.

  This is also why the `#{inspect(__MODULE__)}` struct does not define the
  `const` keyword, because `nil` is a valid value for that keyword but there is
  no way to know if the value was omitted or explicitly defined as `nil`. To
  circumvent that you may use the `enum` keyword or just use a regular map
  instead of this module's struct:

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

  @t_doc "`%#{inspect(__MODULE__)}{}` struct"

  @doc """
  Updates the given schema with the given key/values.

  This function accepts a base schema and override values that will be merged
  into the base.

  The resulting schema is always a map or a struct but depends on the given
  base. If follows the followng rules. See the examples below.

  * The base type is not changed when it is a map or struct:
    - If the base is a #{@t_doc}, the overrides are merged in.
    - If the base is another struct, the overrides a merged in but it fails if
      the struct does not define the overriden keys.
    - If the base is a mere map, **it is not** turned into a #{@t_doc} and the
      overrides are merged in.

  * Otherwise the base is casted to a #{@t_doc}:
    - If the base is `nil`, the function returns a #{@t_doc} with the given
      overrides.
    - If the base is a keyword list, the list will be turned into a #{@t_doc}
    and the `overrides` will then be merged in.

  ## Examples

      iex> JSV.Schema.override(%JSV.Schema{description: "base"}, %{type: :integer})
      %JSV.Schema{description: "base", type: :integer}

      defmodule CustomSchemaStruct do
        defstruct [:type, :description]
      end

      iex> JSV.Schema.override(%CustomSchemaStruct{description: "base"}, %{type: :integer})
      %CustomSchemaStruct{description: "base", type: :integer}

      iex> JSV.Schema.override(%CustomSchemaStruct{description: "base"}, %{format: :date})
      ** (KeyError) struct CustomSchemaStruct does not accept key :format

      iex> JSV.Schema.override(%{description: "base"}, %{type: :integer})
      %{description: "base", type: :integer}

      iex> JSV.Schema.override(nil, %{type: :integer})
      %JSV.Schema{type: :integer}

      iex> JSV.Schema.override([description: "base"], %{type: :integer})
      %JSV.Schema{description: "base", type: :integer}
  """
  @doc section: :schema_utilities
  @spec override(base, overrides) :: schema
  def override(nil, overrides) do
    new(overrides)
  end

  def override(base, overrides) when is_list(base) do
    struct!(new(base), overrides)
  end

  # shortcut for required/2. The previous clauses will cast nil and lists to a
  # struct. From there, if there is nothing to override we can just return the
  # base.
  def override(base, []) when is_map(base) do
    base
  end

  def override(%mod{} = base, overrides) do
    struct!(base, overrides)
  rescue
    e in KeyError ->
      reraise %{e | message: "struct #{inspect(mod)} does not accept key #{inspect(e.key)}"}, __STACKTRACE__
  end

  def override(base, overrides) when is_map(base) do
    Enum.into(overrides, base)
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
  Overrides the [base schema](JSV.Schema.html#override/2) with `required: keys`
  or merges the given `keys` in the predefined keys.

  Adds or merges the given keys as required in the base schema. Existing
  required keys are preserved.

  ### Examples

      iex> JSV.Schema.required(%{}, [:a, :b])
      %{required: [:a, :b]}

      iex> JSV.Schema.required(%{required: nil}, [:a, :b])
      %{required: [:a, :b]}

      iex> JSV.Schema.required(%{required: [:c]}, [:a, :b])
      %{required: [:a, :b, :c]}

      iex> JSV.Schema.required(%{required: [:a]}, [:a])
      %{required: [:a, :a]}

  Use `override/2` to replace existing required keys.

      iex> JSV.Schema.override(%{required: [:a, :b, :c]}, required: [:x, :y, :z])
      %{required: [:x, :y, :z]}
  """
  @doc section: :schema_utilities
  @spec required(base, [atom | binary]) :: t
  def required(base \\ nil, key_or_keys)

  def required(nil, keys) when is_list(keys) do
    new(required: keys)
  end

  def required(base, keys) when is_list(keys) do
    case override(base, []) do
      %{required: list} = cast_base when is_list(list) -> override(cast_base, required: keys ++ list)
      cast_base -> override(cast_base, required: keys)
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
        as_string = Atom.to_string(atom)

        if schema_module?(atom, as_string) do
          {%{"$ref" => Internal.module_to_uri(atom)}, [atom | acc]}
        else
          {as_string, acc}
        end
      end
    ]

    {normal, _acc} = JSV.Normalizer.normalize(term, normalize_opts, [])

    normal
  end

  # Returns whether the given atom is a module exporting a schema.
  @common_atom_values [
    :array,
    :object,
    :null,
    :boolean,
    :string,
    :integer,
    :number,
    true,
    false,
    nil
  ]
  defp schema_module?(module, _) when module in @common_atom_values do
    false
  end

  defp schema_module?(module, _as_string) do
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
    def normalize(schema) do
      JSV.Schema.to_map(schema)
    end
  end
end
