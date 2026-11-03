defmodule JSV.Validator.ValidationContext do
  @moduledoc """
  Validation context carried along by the `JSV.Validator` and given to all
  vocabulary implementations.

  This struct is used to store errors found during validation, and to hold
  contextual information such as the current path in the data or in the
  schema.
  """

  # :eval_path stores both the current keyword nesting leading to an error, and
  # the namespace changes for error absolute location.

  require Record

  # Fields that do not change during a validation are grouped in a record, so
  # the context map stays small and checking a flag is a single map lookup.
  @config_keys [:validators, :opts, :feature_cast, :feature_unevaluated, :feature_errors]

  Record.defrecord(:__cfg, :config, @config_keys)

  @enforce_keys [
    :config,
    :scope,
    :errors,
    :evaluated,
    :data_path,
    :eval_path,
    :schema_path,
    :seen_refs,
    :cast_stack
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}
  @type config_key ::
          unquote(
            Enum.reduce(
              @config_keys,
              &quote do
                unquote(&1) | unquote(&2)
              end
            )
          )

  @doc """
  Returns a setting of the validation that does not change while validating,
  such as `:opts`, the validation options given to `JSV.validate/3`.
  """
  @spec config(t, config_key) :: term
  def config(vctx, key)

  for key <- @config_keys do
    def config(__cfg([{unquote(key), value}]), unquote(key)) do
      value
    end
  end

  def config(%__MODULE__{config: config}, key) do
    config(config, key)
  end
end
