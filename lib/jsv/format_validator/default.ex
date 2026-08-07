defmodule JSV.FormatValidator.Default do
  import JSV.FormatValidator.Default.Optional
  alias JSV.FormatValidator.Default.Optional

  @moduledoc false

  @behaviour JSV.FormatValidator

  @supports_duration Code.ensure_loaded?(Duration)

  @formats [
             "ipv4",
             "ipv6",
             "unknown",
             "regex",
             "date",
             "date-time",
             "time",
             "hostname",
             "uri",
             "uri-reference",
             "uuid",
             "email",
             "iri",
             "iri-reference",
             "uri-template",
             "json-pointer",
             "relative-json-pointer",
             optional_support("duration", @supports_duration)
           ]
           |> :lists.flatten()
           |> Enum.sort()

  @impl true
  def supported_formats do
    @formats
  end

  # Default formats in the specification only apply to strings
  @impl true
  def applies_to_type?(_any_format, data) do
    is_binary(data)
  end

  # RFC 3339 requires the time offset to be "Z" or a full "+hh:mm"/"-hh:mm", but
  # Elixir also accepts truncated forms such as "+01".
  @rfc3339_offset ~r/(?:[Zz]|[-+][0-9]{2}:[0-9]{2})\z/

  @impl true
  def validate_cast("date-time", data) do
    case DateTime.from_iso8601(data) do
      {:ok, dt, _} ->
        if String.contains?(data, " ") or not Regex.match?(@rfc3339_offset, data) do
          {:error, :invalid_format}
        else
          {:ok, dt}
        end

      {:error, _} = err ->
        err
    end
  end

  def validate_cast("date", "+" <> _) do
    {:error, :invalid_format}
  end

  def validate_cast("date", "-" <> _) do
    {:error, :invalid_format}
  end

  def validate_cast("date", data) do
    Date.from_iso8601(data)
  end

  # RFC 3339 Appendix A. Elixir's parser is more permissive: it accepts signs,
  # fractional components, a comma as the decimal separator, and mixing weeks
  # with other elements.
  @rfc3339_duration ~r"""
  \AP(?:
    [0-9]+W
    | (?:[0-9]+Y(?:[0-9]+M(?:[0-9]+D)?)?|[0-9]+M(?:[0-9]+D)?|[0-9]+D)
      (?:T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S))?
    | T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S)
  )\z
  """x

  if @supports_duration do
    def validate_cast("duration", data) do
      if Regex.match?(@rfc3339_duration, data) do
        Duration.from_iso8601(data)
      else
        {:error, :invalid_format}
      end
    end
  end

  def validate_cast("time", data) do
    Time.from_iso8601(String.replace(data, "z", "Z"))
  end

  def validate_cast("ipv4", data) do
    case data do
      <<c, _::binary>> when c in ?0..?9 -> :inet.parse_strict_address(String.to_charlist(data))
      _ -> {:error, :einval}
    end
  end

  def validate_cast("ipv6", data) do
    # JSON schema spec does not support zone info suffix in ipv6
    with {:ok, {_, _, _, _, _, _, _, _} = ipv6} <- :inet.parse_strict_address(String.to_charlist(data)),
         false <- String.contains?(data, "%") do
      {:ok, ipv6}
    else
      _ -> {:error, :invalid_ipv6}
    end
  end

  def validate_cast("uuid", data) do
    Optional.UUID.parse_uuid(data)
  end

  def validate_cast("regex", data) do
    Regex.compile(data)
  end

  def validate_cast("unknown", data) do
    {:ok, data}
  end

  def validate_cast("email", data) do
    Optional.EmailAddress.parse_email_address(data)
  end

  def validate_cast("hostname", data) do
    Optional.Hostname.validate(data)
  end

  def validate_cast("iri", data) do
    Optional.IRI.parse_iri(data)
  end

  def validate_cast("iri-reference", data) do
    Optional.IRI.parse_iri_reference(data)
  end

  def validate_cast("uri", data) do
    Optional.URI.parse_uri(data)
  end

  def validate_cast("uri-reference", data) do
    Optional.URI.parse_uri_reference(data)
  end

  def validate_cast("uri-template", data) do
    Texture.UriTemplate.parse(data)
  end

  def validate_cast("json-pointer", data) do
    Optional.JSONPointer.parse_json_pointer(data)
  end

  def validate_cast("relative-json-pointer", data) do
    Optional.JSONPointer.parse_relative_json_pointer(data)
  end
end
