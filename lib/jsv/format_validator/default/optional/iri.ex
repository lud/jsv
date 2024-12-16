require JSV.FormatValidator.Default.Optional

if JSV.FormatValidator.Default.Optional.mod_exists?(AbnfParsec) do
  defmodule JSV.FormatValidator.Default.Optional.IRI do
    use AbnfParsec,
      abnf_file: "priv/iri.abnf",
      unbox: [],
      ignore: []

    def parse_iri(data) do
      case iri(data) do
        {:ok, _, "", _, _, _} -> {:ok, URI.parse(data)}
        _ -> {:error, :invalid_IRI}
      end
    end

    def parse_iri_reference(data) do
      case iri_reference(data) do
        {:ok, _, "", _, _, _} -> {:ok, URI.parse(data)}
        _ -> {:error, :invalid_IRI_reference}
      end
    end
  end
end
