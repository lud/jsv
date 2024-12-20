defmodule JSV do
  alias JSV.BooleanSchema
  alias JSV.Builder
  alias JSV.Root

  @default_default_meta "https://json-schema.org/draft/2020-12/schema"

  @build_opts_schema [
    resolver: [
      type: {:or, [:atom, :mod_arg]},
      required: true,
      doc: "The resolver implementation module to retrieve schemas identified by an URL."
    ],
    default_meta: [
      type: :string,
      doc: ~S(The meta schema to use for resolved schemas that do not define a `"$schema"` property.),
      default: @default_default_meta
    ],
    formats: [
      type: {:or, [:boolean, nil, {:list, :atom}]},
      doc: """
      Controls the validation of strings with the `"format"` keyword.

      * `nil` - Formats are validated according to the meta-schema vocabulary.
      * `true` - Enforces validation with the built-in validator.
      * `false` - Disables all format validation.
      * A list of modules will set those modules as validators. Disables the built-in validator.
      """,
      default: nil
    ]
  ]
  @build_opts_nimble NimbleOptions.new!(@build_opts_schema)

  @doc """
  Builds the schema as a `#{inspect(Root)}` schema for validation.

  ### Options

  #{NimbleOptions.docs(@build_opts_schema)}
  """
  IO.warn("""
  call this function build_opts because the resolver is not an independent
  entity, it is tied to the root schema.

  rename attach_root to resolve_root. Or maybe call that "prepare"
  """)

  def build(raw_schema, opts) when is_map(raw_schema) do
    case NimbleOptions.validate(opts, @build_opts_nimble) do
      {:ok, opts} ->
        builder = Builder.new(opts)
        Builder.build(builder, raw_schema)

      {:error, _} = err ->
        err
    end
  end

  def build(valid?, _opts) when is_boolean(valid?) do
    {:ok, %Root{raw: valid?, root_key: :root, validators: %{root: BooleanSchema.of(valid?)}}}
  end

  @doc """
  Returns the default meta schema used when the `:default_meta` option is not
  set in `build/2`.

  Currently returns #{inspect(@default_default_meta)}.
  """
  def default_meta do
    @default_default_meta
  end

  def validate(data, schema)

  def validate(data, %JSV.Root{} = schema) do
    case validation_entrypoint(schema, data) do
      {:ok, casted_data, _} -> {:ok, casted_data}
      {:error, %JSV.Validator{errors: errors}} -> {:error, {:schema_validation, errors}}
    end
  end

  @doc false
  # entrypoint for tests when we want to return the validator struct
  def validation_entrypoint(%JSV.Root{} = schema, data) do
    %JSV.Root{validators: validators, root_key: root_key} = schema
    root_schema_validators = Map.fetch!(validators, root_key)
    validator = JSV.Validator.new(validators, _scope = [root_key])
    JSV.Validator.validate(data, root_schema_validators, validator)
  end

  def default_format_validator_modules do
    [JSV.FormatValidator.Default]
  end
end
