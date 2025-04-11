defmodule JSV do
  alias JSV.Builder
  alias JSV.ErrorFormatter
  alias JSV.Resolver.Internal
  alias JSV.Root
  alias JSV.ValidationError
  alias JSV.Validator
  alias JSV.Validator.ValidationContext

  @moduledoc """
  JSV is a JSON Schema Validator.

  This module is the main facade for the library.

  To start validating schemas you will need to go through the following steps:

  1. [Obtain a schema](guides/schemas/defining-schemas.md). Schemas can be
     defined in Elixir code, read from files, fetched remotely, _etc_.
  1. [Build a validation root](guides/build/build-basics.md) with `build/2` or
     `build!/2`.
  1. [Validate the data](guides/validation/validation-basics.md).

  ## Example

  Here is an example of the most simple way of using the library:

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
    {:ok, data} ->
      {:ok, data}

    # Errors can be turned into JSON compatible data structure to send them as an
    # API response or for logging purposes.
    {:error, validation_error} ->
      {:error, JSON.encode!(JSV.normalize_error(validation_error))}
  end
  ```

  If you want to explore the different capabilities of the library, please refer
  to the guides provided in this documentation.
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

                         > #### Formats are disabled by the default meta-schema {: .warning}
                         >
                         > The default value for this option is `nil` to respect
                         > the JSON Schema specification where format validation
                         > is enabled via vocabularies.
                         >
                         > The default meta-schemas for the latest drafts (example: `#{@default_default_meta}`)
                         > do not enable format validation.
                         >
                         > You'll probably want this option to be set to `true`
                         > or a list of your own modules.
                         """,
                         default: nil
                       ],
                       vocabularies: [
                         type: {:map, :string, {:or, [:atom, :mod_arg]}},
                         doc: """
                         Allows to redefine modules implementing vocabularies.

                         This option accepts a map with vocabulary URIs as keys and implementations as values.
                         The URIs are not fetched by JSV and does not need to point to anything specific.
                         In the standard Draft 2020-12 meta-schema, these URIs point to human-readable documentation.

                         The given implementations will only be used if the meta-schema used to build a validation root
                         actually declare those URIs in their `$vocabulary` keyword.

                         For instance, to redefine how the `type` keyword and other validation keywords are handled,
                         one should pass the following map:

                             %{
                               "https://json-schema.org/draft/2020-12/vocab/validation" => MyCustomModule
                             }

                         Modules must implement the `JSV.Vocabulary` behaviour.

                         Implementations can also be passed options by wrapping them in a tuple:

                             %{
                               "https://json-schema.org/draft/2020-12/vocab/validation" => {MyCustomModule, opt: "hello"}
                             }
                         """,
                         default: %{}
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
                          cast: [
                            type: :boolean,
                            default: true,
                            doc: """
                            Enables calling generic cast functions on validation.

                            This is based on the `jsv-cast` JSON Schema custom keyword
                            and is typically used by `defschema/1`.

                            While it is on by default, some specific casting features are enabled
                            separately, see option `:cast_formats`.
                            """
                          ],
                          cast_formats: [
                            type: :boolean,
                            default: false,
                            doc: """
                            When enabled, format validators will return casted values,
                            for instance a `Date` struct instead of the date as string.

                            It has no effect when the schema was not built with formats enabled.
                            """
                          ]
                        )

  @doc """
  Validates and casts the data with the given schema. The schema must be a
  `JSV.Root` struct generated with `build/2`.

  > #### This function returns cast data {: .info}
  >
  >
  > * If the `:cast_formats` option is enabled, string values may be transformed
  >   in other data structures. Refer to the "Formats" section of the
  >   [Validation guide](validation-basics.html#formats) for more information.
  > * The JSON Schema specification states that `123.0` is a valid integer. This
  >   function will return `123` instead. This may return invalid data for
  >   floats with very large integer parts. As always when dealing with JSON and
  >   big decimal or extremely precise numbers, use strings.

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

  If the `cast: false` option is given to `JSV.validate/3`, the additional
  properties will be kept.

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
      iex> JSV.validate(data, root, cast: false)
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
      @keycast JSV.StructSupport.keycast_pairs(schema)
      {keys_no_defaults, default_pairs} = JSV.StructSupport.data_pairs_partition(schema)
      required = JSV.StructSupport.list_required(schema)

      @jsv_tag -1

      @jsv_schema schema
                  |> Map.put(:"jsv-cast", [Atom.to_string(__MODULE__), @jsv_tag])
                  |> Map.put_new(:"$id", Internal.module_to_uri(__MODULE__))

      @enforce_keys required
      defstruct keys_no_defaults ++ default_pairs

      def schema do
        @jsv_schema
      end

      @doc false
      def __jsv__(@jsv_tag, data) do
        pairs = JSV.StructSupport.take_keycast(data, @keycast)
        {:ok, struct!(__MODULE__, pairs)}
      end
    end
  end

  # TODO document defschema_for
  @doc false
  defmacro defschema_for(target, schema) do
    quote bind_quoted: binding() do
      :ok = JSV.StructSupport.validate!(schema)
      @target target
      @keycast JSV.StructSupport.keycast_pairs(schema, target)
      {_keys_no_defaults, default_pairs} = JSV.StructSupport.data_pairs_partition(schema)
      @default_pairs default_pairs

      @jsv_tag -2

      @jsv_schema schema
                  |> Map.put(:"jsv-cast", [Atom.to_string(__MODULE__), @jsv_tag])
                  |> Map.put_new(:"$id", Internal.module_to_uri(__MODULE__))

      def schema do
        @jsv_schema
      end

      @doc false
      def __jsv__(@jsv_tag, data) do
        pairs = JSV.StructSupport.take_keycast(data, @keycast)
        pairs = Keyword.merge(@default_pairs, pairs)

        {:ok, struct!(@target, pairs)}
      end
    end
  end

  @doc false
  defguard is_valid_tag(tag) when (is_integer(tag) and tag >= 0) or is_binary(tag)

  @doc false
  defmacro defcast(local_fun) when is_atom(local_fun) do
    defcast_local(__CALLER__, Atom.to_string(local_fun), local_fun)
  end

  defmacro defcast(tag, local_fun) when is_atom(local_fun) and is_valid_tag(tag) do
    defcast_local(__CALLER__, tag, local_fun)
  end

  defmacro defcast(call, [{:do, _} | _] = blocks) do
    {fun, _} = Macro.decompose_call(call)
    tag = Atom.to_string(fun)
    defcast_block(__CALLER__, tag, call, blocks)
  end

  @doc false
  defmacro defcast(tag, call, [{:do, _} | _] = blocks) when is_valid_tag(tag) do
    defcast_block(__CALLER__, tag, call, blocks)
  end

  defp defcast_block(env, tag, call, [{:do, _} | _] = blocks) do
    {fun, arg} =
      case Macro.decompose_call(call) |> dbg(limit: :infinity) do
        {:when, [{err_tag, _, _} | _]} ->
          raise ArgumentError, """
          defcast does not support guards

          You may delegate to a local function like so:

            defcast #{inspect(Atom.to_string(err_tag))} :my_custom_cast_fun

            defp #{Macro.to_string(call)} do
              # ...
            end
          """

        {fun, [arg]} ->
          {fun, arg}

        _ ->
          raise "invalid function call given to defcast"
      end

    mod_str = Atom.to_string(env.module)

    quote do
      def unquote(fun)() do
        [unquote(mod_str), unquote(tag)]
      end

      @doc false
      def __jsv__(unquote(tag), xdata) do
        unquote(fun)(xdata)
      end

      @doc false
      def(unquote(fun)(unquote(arg)), unquote(blocks))
    end
    |> tap(&IO.puts(Macro.to_string(&1)))
  end

  defp defcast_local(_env, tag, local_fun) do
    quote do
      @doc false
      def __jsv__(unquote(tag), xdata) do
        unquote(local_fun)(xdata)
      end
    end
    |> tap(&IO.puts(Macro.to_string(&1)))
  end

  # From https://github.com/fishcakez/dialyze/blob/6698ae582c77940ee10b4babe4adeff22f1b7779/lib/mix/tasks/dialyze.ex#L168
  @doc false
  @spec otp_version :: String.t()
  def otp_version do
    major = :erlang.list_to_binary(:erlang.system_info(:otp_release))
    vsn_file = Path.join([:code.root_dir(), "releases", major, "OTP_VERSION"])

    try do
      vsn_file
      |> File.read!()
      |> String.split("\n", trim: true)
    else
      [full] -> full
      _ -> major
    catch
      :error, _ -> major
    end
  end
end
