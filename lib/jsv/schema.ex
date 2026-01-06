defmodule JSV.Schema do
  alias JSV.Resolver.Internal
  import JSV.Schema.HelperCompiler

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
  @type attributes :: %{(binary | atom) => term} | [{atom | binary, term}]
  @type schema_data :: %{optional(binary) => schema_data} | [schema_data] | number | binary | boolean | nil
  @type merge_base :: attributes | [{atom | binary, term}] | struct | nil
  @type schema :: true | false | map

  @doc """
  Use this module to define module-based schemas or schemas with the helpers
  API.

  * Imports struct and cast definitions from `JSV`.
  * Imports the `JSV.Schema.Helpers` module with the `string`, `integer`,
    `enum`, _etc._ helpers.

  ### Example

      defmodule MySchema do
        use JSV.Schema

        defschema %{
          type: :object,
          properties: %{
            foo: string(description: "Some foo!"),
            bar: integer(minimum: 100) |> with_cast(__MODULE__,:hashid),
            sub: props(sub_foo: string(), sub_bar: integer()) pp
          }
        }

        defcast hashid(bar) do
          {:ok, Hashids.decode!(bar, cipher())}
        end
      end
  """
  defmacro __using__(_) do
    quote do
      import JSV, only: :macros
      import JSV.Schema.Helpers
    end
  end

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
  @spec new(t | attributes) :: t
  def new(%__MODULE__{} = schema) do
    schema
  end

  def new(key_values) when is_list(key_values) when is_map(key_values) do
    struct!(__MODULE__, key_values)
  end

  @doc """
  Merges the given key/values into the base schema. The merge is shallow and
  will overwrite any pre-existing key.

  This function is defined to work with the `JSV.Schema.Composer` API.

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
  @spec merge(merge_base, attributes) :: schema()
  def merge(nil, values) do
    new(values)
  end

  def merge(merge_base, values) when is_list(merge_base) do
    struct!(new(merge_base), values)
  end

  def merge(%mod{} = merge_base, values) do
    struct!(merge_base, values)
  rescue
    e in KeyError ->
      reraise %{e | message: "struct #{inspect(mod)} does not accept key #{inspect(e.key)}"}, __STACKTRACE__
  end

  def merge(merge_base, values) when is_map(merge_base) do
    Enum.into(values, merge_base)
  end

  @doc """
  Merges two sets of attributes into a single map. Attributes can be a keyword
  list or a map.
  """
  @spec combine(attributes, attributes) :: schema
  def combine(map, attributes) when is_map(map) do
    Enum.into(attributes, map)
  end

  def combine(list, attributes) when is_list(list) do
    Enum.into(attributes, Map.new(list))
  end

  @deprecated "Use `JSV.Schema.Composer.merge/2`."
  @doc false
  @spec override(merge_base, attributes) :: schema
  def override(merge_base, values) do
    merge(merge_base, values)
  end

  @doc """
  Includes the cast function in a schema. The cast function must be given as a
  list with two items:

  * A module, as atom or string
  * A tag, as atom, string or integer.

  Atom arguments will be converted to string.

  ### Examples

      iex> JSV.Schema.with_cast([MyApp.Cast, :a_cast_function])
      %JSV.Schema{"jsv-cast": ["Elixir.MyApp.Cast", "a_cast_function"]}

      iex> JSV.Schema.with_cast([MyApp.Cast, 1234])
      %JSV.Schema{"jsv-cast": ["Elixir.MyApp.Cast", 1234]}

      iex> JSV.Schema.with_cast(["some_erlang_module", "custom_tag"])
      %JSV.Schema{"jsv-cast": ["some_erlang_module", "custom_tag"]}
  """
  @spec with_cast(merge_base, [atom | binary | integer, ...]) :: schema()
  def with_cast(merge_base \\ nil, [mod, tag] = _mod_tag)
      when (is_atom(mod) or is_binary(mod)) and (is_atom(tag) or is_binary(tag) or is_integer(tag)) do
    merge(merge_base, "jsv-cast": [to_string_if_atom(mod), to_string_if_atom(tag)])
  end

  @doc false
  @deprecated "Use `with_cast/2` instead."
  @spec cast(merge_base(), [atom | binary | integer, ...]) :: schema()
  def cast(merge_base \\ nil, mod_tag) do
    with_cast(merge_base, mod_tag)
  end

  defp to_string_if_atom(value) when is_atom(value) do
    Atom.to_string(value)
  end

  defp to_string_if_atom(value) do
    value
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
    exports a `json_schema/0` function.

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

  @doc """
  Behaves like `normalize/1` but all nested module-based schemas are collected
  into `$defs` so the result is a self contained schema, whereas the default
  normalization function returns references for `JSV.Resolver.Internal`.

  Schemas are collected using their title for the key under `$defs`. If multiple
  schemas use the same title, the title is suffixed with `_1`, `_2` and so on.

  This function does not support schemas with pre-existing `$defs`, it will
  ignore them and keep them nested. If such schemas are present and use `$ref`
  to their own definitions, the schema returned from this function may not be
  valid. To prevent this, schemas with definitions should define an `$id` and
  use this in `$ref` references.

  ### Options

  - `:as_root` - boolean, when `true` and used in combination with a
    module-based schema, that module's schema will be kept as the root schema
    instead of being wrapped in a definition. This will overwrite any `$defs`
    present in the schema.
  """
  @spec normalize_collect(term, keyword()) :: %{optional(binary) => schema_data} | atom
  def normalize_collect(term, opts \\ [])

  def normalize_collect(term, opts) when is_atom(term) do
    if Keyword.get(opts, :as_root) == true and schema_module?(term) do
      do_normalize_collect(term.json_schema(), opts)
    else
      do_normalize_collect(term, opts)
    end
  end

  def normalize_collect(term, opts) when is_map(term) do
    do_normalize_collect(term, opts)
  end

  defp do_normalize_collect(term, _opts) when is_atom(term) when is_map(term) do
    # We will have to run several loops. We call the normalizer, replacing
    # modules with a reference, collecting the module in the acc.
    #
    # After the call, if we collected some modules, we merge the refs and start
    # over but we keep the previously used modules and refs so we can skip them
    # and directly use the ref

    accin = %{
      # Collected definitions to merge in the final result
      defs: %{},

      # module to ref, used to see if we handled the module and store the ref
      modules: %{},

      # modules for which we generated a reference and we need to normalize into
      # a definition.
      pending: []
    }

    normalize_opts = [
      on_general_atom: fn atom, acc ->
        if schema_module?(atom) do
          case Map.fetch(acc.modules, atom) do
            {:ok, ref} ->
              {%{"$ref" => ref}, acc}

            :error ->
              schema = from_module(atom)
              title = module_schema_title(schema, atom)
              refname = available_module_schema_refname(acc.defs, title)
              ref = "#/$defs/#{refname}"
              acc = put_in(acc.modules[atom], ref)
              acc = put_in(acc.defs[refname], :__placeholder__)
              acc = update_in(acc.pending, &[{refname, schema} | &1])
              {%{"$ref" => ref}, acc}
          end
        else
          {Atom.to_string(atom), acc}
        end
      end
    ]

    # On the first iteration we get the root schema
    case JSV.Normalizer.normalize(term, accin, normalize_opts) do
      {root_schema, acc} when is_map(root_schema) ->
        {pending, acc} = get_and_update_in(acc.pending, &{&1, []})

        defs = normalize_collect_defs(pending, acc, normalize_opts)

        case map_size(defs) do
          0 -> root_schema
          _ -> Map.put(root_schema, "$defs", defs)
        end

      {other, _} ->
        other
    end
  end

  defp normalize_collect_defs([{refname, schema} | pending], acc, normalize_opts) do
    {def_schema, acc} = JSV.Normalizer.normalize(schema, acc, normalize_opts)

    acc = update_in(acc.defs[refname], fn :__placeholder__ -> def_schema end)
    normalize_collect_defs(pending, acc, normalize_opts)
  end

  defp normalize_collect_defs([], acc, normalize_opts) do
    case acc.pending do
      [] ->
        acc.defs

      more ->
        acc = Map.put(acc, :pending, [])
        normalize_collect_defs(more, acc, normalize_opts)
    end
  end

  defp module_schema_title(%{"title" => title}, _module) when is_binary(title) and title != "" do
    title
  end

  defp module_schema_title(%{title: title}, _module) when is_binary(title) and title != "" do
    title
  end

  defp module_schema_title(_schema, module) do
    inspect(module)
  end

  # we do not append a number at the end of the title on the first try
  defp available_module_schema_refname(schemas, title) do
    if Map.has_key?(schemas, title) do
      available_module_schema_refname(schemas, title, 1)
    else
      title
    end
  end

  defp available_module_schema_refname(_schemas, title, n) when n > 1000 do
    # This should not happen but lets not iterate forever
    raise "could not generate a unique name for #{title}"
  end

  defp available_module_schema_refname(schemas, title, n) do
    name = "#{title}_#{Integer.to_string(n)}"

    if Map.has_key?(schemas, name) do
      available_module_schema_refname(schemas, title, n + 1)
    else
      name
    end
  end

  @common_atom_values [
    true,
    false,
    nil,
    # Common types
    :array,
    :boolean,
    :enum,
    :integer,
    :null,
    :number,
    :object,
    :string,
    # Common Elixir
    :ok,
    :error,
    :date,
    # Formats
    :ipv4,
    :ipv6,
    :unknown,
    :regex,
    :date,
    :"date-time",
    :time,
    :hostname,
    :uri,
    :"uri-reference",
    :uuid,
    :email,
    :iri,
    :"iri-reference",
    :"uri-template",
    :"json-pointer",
    :"relative-json-pointer"
  ]

  @doc """
  Returns whether the given atom is a module with a `schema/0` exported
  function.
  """
  @spec schema_module?(atom) :: boolean
  def schema_module?(module) when module in @common_atom_values do
    false
  end

  # TODO(schema-fun): Remove check for the schema/0 function
  def schema_module?(module) do
    case Code.ensure_compiled(module) do
      {:error, _} ->
        false

      {:module, ^module} ->
        Code.ensure_loaded!(module)
        function_exported?(module, :json_schema, 0) || function_exported?(module, :schema, 0)
    end
  end

  # TODO(schema-fun): Remove support for the schema/0 function
  @doc """
  Calls the `json_schema/0` function on the given module, with a fallback to the
  deprecated `schema/0` function if exported.
  """
  @spec from_module(module) :: schema()
  def from_module(module) do
    module.json_schema()
  rescue
    e in UndefinedFunctionError ->
      with %{module: ^module, function: :json_schema, arity: 0} <- e,
           true <- function_exported?(module, :schema, 0) do
        IO.warn(
          "JSON schemas modules exporting a schema/0 function are deprecated, " <>
            "please export a json_schema/0 function instead",
          __STACKTRACE__
        )

        module.schema()
      else
        _ -> reraise e, __STACKTRACE__
      end
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

  defcompose_deprecated(:boolean, 0)
  defcompose_deprecated(:date, 0)
  defcompose_deprecated(:datetime, 0)
  defcompose_deprecated(:email, 0)
  defcompose_deprecated(:integer, 0)
  defcompose_deprecated(:neg_integer, 0)
  defcompose_deprecated(:non_empty_string, 0)
  defcompose_deprecated(:non_neg_integer, 0)
  defcompose_deprecated(:number, 0)
  defcompose_deprecated(:object, 0)
  defcompose_deprecated(:pos_integer, 0)
  defcompose_deprecated(:string_to_atom, 0)
  defcompose_deprecated(:string_to_boolean, 0)
  defcompose_deprecated(:string_to_existing_atom, 0)
  defcompose_deprecated(:string_to_float, 0)
  defcompose_deprecated(:string_to_integer, 0)
  defcompose_deprecated(:string_to_number, 0)
  defcompose_deprecated(:string, 0)
  defcompose_deprecated(:uri, 0)
  defcompose_deprecated(:uuid, 0)

  defcompose_deprecated(:all_of, 1)
  defcompose_deprecated(:any_of, 1)
  defcompose_deprecated(:array_of, 1)
  defcompose_deprecated(:format, 1)
  defcompose_deprecated(:items, 1)
  defcompose_deprecated(:one_of, 1)
  defcompose_deprecated(:properties, 1)
  defcompose_deprecated(:props, 1)
  defcompose_deprecated(:ref, 1)
  defcompose_deprecated(:required, 1)
  defcompose_deprecated(:string_of, 1)
  defcompose_deprecated(:string_to_atom_enum, 1)
end
