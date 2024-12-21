defmodule JSV.Validator.Error do
  @enforce_keys [:kind, :data, :args, :formatter, :data_path, :eval_path]
  defstruct @enforce_keys

  @opaque t :: %__MODULE__{}

  def format(%__MODULE__{} = error) do
    %__MODULE__{kind: kind, data: data, formatter: formatter, args: args} =
      error

    formatter = formatter || __MODULE__
    args_map = Map.new(args)

    case formatter.format_error(kind, args_map, data) do
      message when is_binary(message) -> %{message: message, kind: kind}
      {message, detail} when is_binary(message) -> Map.merge(detail, %{message: message, kind: kind})
    end
  end

  def format_error(:boolean_schema, %{}, _data) do
    "value was rejected from boolean schema: false"
  end
end
