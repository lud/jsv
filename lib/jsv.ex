defmodule JSV do
  def build(raw_schema, opts) do
    JSV.Root.build(raw_schema, opts)
  end

  def validate(%JSV.Root{} = schema, data) do
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
    JSV.Validator.validate(data, root_schema_validators, JSV.Validator.new(schema))
  end

  def default_format_validator_modules do
    [JSV.FormatValidator.Default]
  end
end
