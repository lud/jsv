require JSV.FormatValidator.Default.Optional

if JSV.FormatValidator.Default.Optional.mod_exists?(AbnfParsec) do
  defmodule JSV.FormatValidator.Default.Optional.JSONPointer do
    @moduledoc false
    @external_resource "priv/json-pointer.abnf"

    use AbnfParsec,
      abnf_file: "priv/json-pointer.abnf",
      unbox: [],
      ignore: []

    @spec parse_json_pointer(binary) :: {:ok, binary} | {:error, term}
    def parse_json_pointer(data) do
      case json_pointer(data) do
        {:ok, _, "", _, _, _} -> {:ok, data}
        _ -> {:error, :invalid_JSON_pointer}
      end
    end

    @spec parse_relative_json_pointer(binary) :: {:ok, binary} | {:error, term}
    def parse_relative_json_pointer(data) do
      case relative_json_pointer(data) do
        {:ok, _, "", _, _, _} -> {:ok, data}
        _ -> {:error, :invalid_relative_JSON_pointer}
      end
    end
  end
end
