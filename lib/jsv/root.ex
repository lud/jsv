defmodule JSV.Root do
  defstruct validators: %{},
            root_key: nil,
            raw: nil

  @opaque t :: %__MODULE__{}
end
