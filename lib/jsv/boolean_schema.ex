defmodule JSV.BooleanSchema do
  defstruct [:valid?]

  def of(true) do
    %__MODULE__{valid?: true}
  end

  def of(false) do
    %__MODULE__{valid?: false}
  end

  def valid?(%{valid?: valid?}) do
    valid?
  end
end
