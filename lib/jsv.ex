defmodule JSV do
  alias JSV.Builder
  alias JSV.ErrorFormatter
  alias JSV.Resolver.Internal
  alias JSV.Root
  alias JSV.ValidationError
  alias JSV.Validator
  alias JSV.Validator.ValidationContext

  readme =
    "README.md"
    |> File.read!()
    |> String.split("<!-- moduledoc-split -->")
    |> tl()

  @moduledoc """
  This is the main API for the JSV library.

  #{readme}
  """

  @type raw_schema :: map() | boolean() | module()

  @default_default_meta "https://json-schema.org/draft/2020-12/schema"

  @build_opts_schema NimbleOptions.new!(
                       resolver: [
                         type: {:or, [:atom, :mod_arg, {:list, {:or, [:atom, :mod_arg]}}]},
                         default: [],
                         doc: """
                         The `JSV.Resolver` behaviour implementation module to
                         retrieve schemas identified by an URL.

                         Accepts a `module`, a `{module, options}` tuple or a
                         list of those forms.

                         The options can be any term and will be given to the
                         `resolve/2` callback of the module.

                         The `JSV.Resolver.Embedded` and `JSV.Resolver.Internal`
                         will be automatically appended to support module-based
                         schemas and meta-schemas.
                         """
                       ],
                       default_meta: [
                         type: :string,
                         doc:
                           ~S(The meta schema to use for resolved schemas that do not define a `"$schema"` property.),
                         default: @default_default_meta
                       ],
                       formats: [
                         type: {:or, [:boolean, nil, {:list, :atom}]},
                         doc: """
                         Controls the validation of strings with the `"format"` keyword.

                         * `nil` - Formats are validated according to the meta-schema vocabulary.
                         * `true` - Enforces validation with the default validator modules.
                         * `false` - Disables all format validation.
                         * `[Module1, Module2,...]` – set those modules as validators. Disables the default format validator modules.
                            The default validators can be included back in the list manually, see `default_format_validator_modules/0`.

                         > #### Formats are disabled by the default meta-schemas {: .warning}
                         >
                         > The default value for this option is `nil` to respect
                         > the capability of enably validation with vocabularies.
                         >
                         > But the default meta-schemas for the latest drafts (example: `#{@default_default_meta}`)
                         > do not enable format validation.
                         >
                         > You'll probably want this option to be set to `true`
                         > or to provide your own modules.
                         """,
                         default: nil
                       ]
                     )

  @doc """
  Builds the schema as a `#{inspect(Root)}` schema for validation.

  ### Options

  #{NimbleOptions.docs(@build_opts_schema)}
  """
  @spec build(JSV.raw_schema(), keyword) :: {:ok, Root.t()} | {:error, Exception.t()}
  def build(raw_schema, opts \\ [])

  def build(raw_schema, opts) when is_map(raw_schema) when is_atom(raw_schema) do
    case NimbleOptions.validate(opts, @build_opts_schema) do
      {:ok, opts} ->
        builder =
          opts
          |> build_resolvers()
          |> Builder.new()

        case Builder.build(builder, raw_schema) do
          {:ok, root} -> {:ok, root}
          {:error, reason} -> {:error, %JSV.BuildError{reason: reason}}
        end

      {:error, _} = err ->
        err
    end
  end

  defp build_resolvers(opts) do
    {resolvers, opts} = Keyword.pop!(opts, :resolver)
    resolvers = List.wrap(resolvers)
    extra = [JSV.Resolver.Internal, JSV.Resolver.Embedded] -- resolvers

    resolvers =
      Enum.map(resolvers ++ extra, fn
        {module, res_opts} -> {module, res_opts}
        module -> {module, []}
      end)

    Keyword.put(opts, :resolvers, resolvers)
  end

  @doc """
  Same as `build/2` but raises on error.
  """
  @spec build!(JSV.raw_schema(), keyword) :: Root.t()
  def build!(raw_schema, opts \\ [])

  def build!(raw_schema, opts) do
    case build(raw_schema, opts) do
      {:ok, root} -> root
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Returns the default meta schema used when the `:default_meta` option is not
  set in `build/2`.

  Currently returns #{inspect(@default_default_meta)}.
  """
  @spec default_meta :: binary
  def default_meta do
    @default_default_meta
  end

  @validate_opts_schema NimbleOptions.new!(
                          cast_formats: [
                            type: :boolean,
                            default: false,
                            doc:
                              "When enabled, format validators will return casted values, " <>
                                "for instance a `Date` struct instead of the date as string. " <>
                                "It has no effect when the schema was not built with formats enabled."
                          ],
                          cast_structs: [
                            type: :boolean,
                            default: true,
                            doc:
                              "When enabled, schemas defining the jsv-struct keyword " <>
                                "will be casted to the corresponding module. " <>
                                "This keyword is automatically set by schemas used in `JSV.defschema/1`."
                          ]
                        )

  @doc """
  Validates and casts the data with the given schema. The schema must be a
  `JSV.Root` struct generated with `build/2`.

  **Important**: this function returns casted data:

  * If the `:cast_formats` option is enabled, string values may be transformed
    in other data structures. Refer to the "Formats" section of the `JSV`
    documentation for more information.
  * The JSON Schema specification states that `123.0` is a valid integer. This
    function will return `123` instead. This may return invalid data for floats
    with very large integer parts. As always when dealing with JSON and big
    decimal or extremely precise numbers, use strings.
  * Future versions of the library will allow to cast raw data into Elixir
    structs.

  ### Options

  #{NimbleOptions.docs(@validate_opts_schema)}
  """
  @spec validate(term, JSV.Root.t(), keyword) :: {:ok, term} | {:error, Exception.t()}
  def validate(data, root, opts \\ [])

  def validate(data, %JSV.Root{} = root, opts) do
    case NimbleOptions.validate(opts, @validate_opts_schema) do
      {:ok, opts} ->
        case validation_entrypoint(root, data, opts) do
          {:ok, casted_data, _} -> {:ok, casted_data}
          {:error, %ValidationContext{} = validator} -> {:error, Validator.to_error(validator)}
        end

      {:error, _} = err ->
        err
    end
  end

  @spec normalize_error(ValidationError.t() | Validator.context() | [Validator.Error.t()]) :: map()
  def normalize_error(%ValidationError{} = error) do
    ErrorFormatter.normalize_error(error)
  end

  def normalize_error(errors) when is_list(errors) do
    normalize_error(ValidationError.of(errors))
  end

  # TODO provide a way to return ordered json for errors, or just provide a
  # preprocess function.
  def normalize_error(%ValidationContext{} = validator) do
    normalize_error(Validator.to_error(validator))
  end

  @doc false
  # direct entrypoint for tests when we want to get the returned context.
  @spec validation_entrypoint(term, term, term) :: Validator.result()
  def validation_entrypoint(%JSV.Root{} = schema, data, opts) do
    %JSV.Root{validators: validators, root_key: root_key} = schema
    root_schema_validators = Map.fetch!(validators, root_key)
    context = JSV.Validator.context(validators, _scope = [root_key], opts)
    JSV.Validator.validate(data, root_schema_validators, context)
  end

  @doc """
  Returns the list of format validator modules that are used when a schema is
  built with format validation enabled and the `:formats` option to `build/2` is
  `true`.
  """
  @spec default_format_validator_modules :: [module]
  def default_format_validator_modules do
    [JSV.FormatValidator.Default]
  end

  @doc """
  Defines a struct in the calling module where the struct keys are the
  properties of the schema.

  If a default value is given in a property schema, it will be used as the
  default value for the corresponding struct key. Otherwise, the default value
  will be `nil`. A default value is _not_ validated against the property schema
  itself.

  The `$id` property of the schema will automatically be set, if not present, to
  `"jsv:module:" <> Atom.to_string(__MODULE__)`. Because of this, module based
  schemas must avoid using relative references to a parent schema as the
  references will resolve to that generated `$id`.

  ### Additional properties

  Additional properties are allowed.

  If your schema does not define `additionalProperties: false`, the validation
  will accept a map with additional properties, but the keys will not be added
  to the resulting struct as it would be invalid.

  If the `cast_structs: false` option is given to `JSV.validate/3`, the
  additional properties will be kept.

  ### Example

  Given the following module definition:

      defmodule MyApp.UserSchema do
        require JSV

        JSV.defschema(%{
          type: :object,
          properties: %{
            name: %{type: :string, default: ""},
            age: %{type: :integer, default: 0}
          }
        })
      end

  We can get the struct with default values:

      iex> %MyApp.UserSchema{}
      %MyApp.UserSchema{name: "", age: 0}

  And we can use the module as a schema:

      iex> {:ok, root} = JSV.build(MyApp.UserSchema)
      iex> data = %{"name" => "Alice"}
      iex> JSV.validate(data, root)
      {:ok, %MyApp.UserSchema{name: "Alice", age: 0}}

  Additional properties are ignored:

      iex> {:ok, root} = JSV.build(MyApp.UserSchema)
      iex> data = %{"name" => "Alice", "extra" => "hello!"}
      iex> JSV.validate(data, root)
      {:ok, %MyApp.UserSchema{name: "Alice", age: 0}}

  Disabling struct casting with additional properties:

      iex> {:ok, root} = JSV.build(MyApp.UserSchema)
      iex> data = %{"name" => "Alice", "extra" => "hello!"}
      iex> JSV.validate(data, root, cast_structs: false)
      {:ok, %{"name" => "Alice", "extra" => "hello!"}}

  A module can reference another module:

      defmodule MyApp.CompanySchema do
        require JSV

        JSV.defschema(%{
          type: :object,
          properties: %{
            name: %{type: :string},
            owner: MyApp.UserSchema
          }
        })
      end

      iex> {:ok, root} = JSV.build(MyApp.CompanySchema)
      iex> data = %{"name" => "Schemas Inc.", "owner" => %{"name" => "Alice"}}
      iex> JSV.validate(data, root)
      {:ok, %MyApp.CompanySchema{name: "Schemas Inc.", owner: %MyApp.UserSchema{name: "Alice", age: 0}}}
  """
  defmacro defschema(schema) do
    quote bind_quoted: binding() do
      :ok = JSV.StructSupport.validate!(schema)
      keycast_pairs = JSV.StructSupport.keycast_pairs(schema)
      {keys_no_defaults, default_pairs} = JSV.StructSupport.data_pairs_partition(schema)
      required = JSV.StructSupport.list_required(schema)

      # It is important to set the jsv-struct as a binary, otherwise it would be
      # turned into a $ref when the schema will be denormalized by the resolver.
      #
      # Also we set those keys as atoms because the rest of the schema has to be
      # defined with atoms and we do not want to mix key types at this point.
      @jsv_schema schema
                  |> Map.put(:"jsv-struct", Atom.to_string(__MODULE__))
                  |> Map.put_new(:"$id", Internal.module_to_uri(__MODULE__))

      @enforce_keys required
      defstruct keys_no_defaults ++ default_pairs

      def schema do
        @jsv_schema
      end

      @doc false
      def __jsv__(arg)

      def __jsv__(:keycast) do
        unquote(keycast_pairs)
      end

      def __jsv__(:defaults_override) do
        # No need to return defaults as defaults values are handled by the
        # __struct__ functions. So we can return an empty list of pairs.
        []
      end
    end
  end

  defmacro defschema_for(target, schema) do
    quote bind_quoted: binding() do
      :ok = JSV.StructSupport.validate!(schema)
      keycast_pairs = JSV.StructSupport.keycast_pairs(schema, target)
      {_keys_no_defaults, default_pairs} = JSV.StructSupport.data_pairs_partition(schema)

      # When defining a schema for another struct we will add two internal
      # keywords. The $id is still derived from the schema module as we may want
      # to define multiple schemas targetting a common struct.
      @jsv_schema schema
                  |> Map.put(:"jsv-schema", Atom.to_string(__MODULE__))
                  |> Map.put(:"jsv-struct", Atom.to_string(target))
                  |> Map.put_new(:"$id", Internal.module_to_uri(__MODULE__))

      def schema do
        @jsv_schema
      end

      @doc false
      def __jsv__(arg)

      def __jsv__(:keycast) do
        unquote(keycast_pairs)
      end

      def __jsv__(:defaults_override) do
        unquote(default_pairs)
      end
    end
  end
end
