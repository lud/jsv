defmodule JSV.Schema.Composer do
  alias JSV.Schema
  import JSV.Schema.HelpersCompiler

  @moduledoc """
  This module contains a composable API to build schemas in a functionnal way.

  Every function will return a schema and accepts an optional _first_ argument
  to merge onto, using `JSV.Schema.merge/2`.

  See `JSV.Schema.Helpers` to work with a more "presets" oriented API.

  ## Example

      iex> %JSV.Schema{}
      ...> |> object()
      ...> |> properties(foo: string())
      ...> |> required([:foo])
      %JSV.Schema{type: :object, properties: %{foo: %JSV.Schema{type: :string}}, required: [:foo]}
  """

  @type property_key :: atom | binary
  @type nested_schema :: JSV.native_schema()
  @type properties :: [{property_key, nested_schema}] | %{optional(property_key) => nested_schema}

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
  @spec items(Schema.merge_base(), nested_schema) :: Schema.schema()
  def items(merge_base \\ nil, item_schema) do
    Schema.merge(merge_base, %{items: item_schema})
  end

  @doc "Defines or merges onto a JSON Schema with `type: :array` and `items: item_schema`."
  @spec array_of(Schema.merge_base(), nested_schema) :: Schema.schema()
  def array_of(merge_base \\ nil, item_schema) do
    Schema.merge(merge_base, %{type: :array, items: item_schema})
  end

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
  @spec format(Schema.merge_base(), atom | binary) :: Schema.schema()
  def format(merge_base \\ nil, format) when is_binary(format) when is_atom(format) do
    Schema.merge(merge_base, %{format: format})
  end

  @doc "Defines or merges onto a JSON Schema with `type: :string` and `format: format`."
  @spec string_of(Schema.merge_base(), atom | binary) :: Schema.schema()
  def string_of(merge_base \\ nil, format) when is_binary(format) when is_atom(format) do
    Schema.merge(merge_base, %{type: :string, format: format})
  end

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
  @spec ref(Schema.merge_base(), String.t()) :: Schema.schema()
  def ref(merge_base \\ nil, ref) do
    Schema.merge(merge_base, %{"$ref": ref})
  end

  @doc """
  Does **not** set the `type: :object` on the schema. Use `props/2` for a
  shortcut.
  """
  @spec properties(Schema.merge_base(), properties) :: Schema.schema()
  def properties(merge_base \\ nil, properties) when is_list(properties) when is_map(properties) do
    Schema.merge(merge_base, %{properties: Map.new(properties)})
  end

  @doc "Defines or merges onto a JSON Schema with `type: :object` and `properties: properties`."
  @spec props(Schema.merge_base(), properties) :: Schema.schema()
  def props(merge_base \\ nil, properties) when is_list(properties) when is_map(properties) do
    Schema.merge(merge_base, %{type: :object, properties: Map.new(properties)})
  end

  @doc "Defines or merges onto a JSON Schema with `allOf: schemas`."
  @spec all_of(Schema.merge_base(), [nested_schema]) :: Schema.schema()
  def all_of(merge_base \\ nil, schemas) when is_list(schemas) do
    Schema.merge(merge_base, %{allOf: schemas})
  end

  @doc "Defines or merges onto a JSON Schema with `anyOf: schemas`."
  @spec any_of(Schema.merge_base(), [nested_schema]) :: Schema.schema()
  def any_of(merge_base \\ nil, schemas) when is_list(schemas) do
    Schema.merge(merge_base, %{anyOf: schemas})
  end

  @doc "Defines or merges onto a JSON Schema with `oneOf: schemas`."
  @spec one_of(Schema.merge_base(), [nested_schema]) :: Schema.schema()
  def one_of(merge_base \\ nil, schemas) when is_list(schemas) do
    Schema.merge(merge_base, %{oneOf: schemas})
  end

  defcompose :string_to_integer, type: :string, "x-jsv-cast": [JSV.Cast.string_to_integer()]
  defcompose :string_to_float, type: :string, "x-jsv-cast": [JSV.Cast.string_to_float()]
  defcompose :string_to_number, type: :string, "x-jsv-cast": [JSV.Cast.string_to_number()]
  defcompose :string_to_boolean, type: :string, "x-jsv-cast": [JSV.Cast.string_to_boolean()]
  defcompose :string_to_existing_atom, type: :string, "x-jsv-cast": [JSV.Cast.string_to_existing_atom()]
  defcompose :string_to_atom, type: :string, "x-jsv-cast": [JSV.Cast.string_to_atom()]

  @doc """
  Accepts a list of atoms and validates that a given value is a string
  representation of one of the given atoms.

  On validation, a cast will be made to return the original atom value.

  This is useful when dealing with enums that are represented as atoms in the
  codebase, such as Oban job statuses or other Ecto enum types.

      iex> schema = JSV.Schema.Composer.props(status: JSV.Schema.Composer.string_to_atom_enum([:executing, :pending]))
      iex> root = JSV.build!(schema, atoms: true)
      iex> JSV.validate(%{"status" => "pending"}, root)
      {:ok, %{"status" => :pending}}

  > #### Does not support `nil` {: .warning}
  >
  > This function sets the `string` type on the schema. If `nil` is given in the
  > enum, the corresponding valid JSON value will be the `"nil"` string rather
  > than `null`
  """
  @spec string_to_atom_enum(Schema.merge_base(), [atom]) :: Schema.schema()
  def string_to_atom_enum(merge_base \\ nil, enum) when is_list(enum) do
    # We need to cast atoms to string, otherwise if `nil` is provided
    # it will be JSON-encoded as `nil` instead of `"null". But this
    # caster only accepts strings.
    Schema.merge(merge_base, %{
      type: :string,
      enum: Enum.map(enum, &Atom.to_string/1),
      "x-jsv-cast": [JSV.Cast.string_to_atom()]
    })
  end

  @doc """
  Defines a JSON Schema with `required: keys` or adds the given `keys` if the
  [base schema](JSV.Schema.html#merge/2) already has a `:required`
  definition.

  Existing required keys are preserved.

  ### Examples

      iex> JSV.Schema.Composer.required(%{}, [:a, :b])
      %{required: [:a, :b]}

      iex> JSV.Schema.Composer.required(%{required: nil}, [:a, :b])
      %{required: [:a, :b]}

      iex> JSV.Schema.Composer.required(%{required: [:c]}, [:a, :b])
      %{required: [:a, :b, :c]}

      iex> JSV.Schema.Composer.required(%{required: [:a]}, [:a])
      %{required: [:a, :a]}

  Use `JSV.Schema.merge/2` to replace existing required keys.

      iex> JSV.Schema.merge(%{required: [:a, :b, :c]}, required: [:x, :y, :z])
      %{required: [:x, :y, :z]}
  """
  @spec required(Schema.merge_base(), [atom | binary]) :: Schema.schema()
  def required(merge_base \\ nil, key_or_keys)

  def required(nil, keys) when is_list(keys) do
    Schema.new(required: keys)
  end

  def required(merge_base, keys) when is_list(keys) do
    case Schema.merge(merge_base, []) do
      %{required: list} = map when is_list(list) -> Schema.merge(map, required: keys ++ list)
      map -> Schema.merge(map, required: keys)
    end
  end
end
