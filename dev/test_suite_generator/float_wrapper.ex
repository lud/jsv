# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.TestSuiteGenerator.FloatWrapper do
  @moduledoc false
  defstruct [:float_str]

  def new(float_str) when is_binary(float_str) do
    %__MODULE__{float_str: float_str}
  end

  def as_json_decoded(%__MODULE__{float_str: float_str}) do
    JSON.decode!(float_str)
  end

  def as_elixir_code(%__MODULE__{} = fw) do
    inspect(as_json_decoded(fw))
  end
end
