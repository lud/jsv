defmodule JSV.FormatValidator.Default do
  import JSV.FormatValidator.Default.Optional
  alias JSV.FormatValidator.Default.Optional

  # When changing implementation of formats, please make sure to keep the list
  # of special cases up-to-date in dev/doc_gen/generator.ex
  #
  # List anything that JSV does different from the JSON Schema specification or
  # various RFC, and also what JSV does when a behaviour is unspecified.

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

  @impl true
  def validate_cast("date-time", <<date::binary-size(10), sep, time::binary>> = data)
      when sep in [?T, ?t] do
    if full_date?(date) and full_time?(time) do
      case DateTime.from_iso8601(String.upcase(data)) do
        {:ok, dt, _} -> {:ok, dt}
        {:error, _} = err -> err
      end
    else
      {:error, :invalid_format}
    end
  end

  def validate_cast("date-time", _data) do
    {:error, :invalid_format}
  end

  def validate_cast("date", data) do
    if full_date?(data) do
      Date.from_iso8601(data)
    else
      {:error, :invalid_format}
    end
  end

  if @supports_duration do
    def validate_cast("duration", data) do
      if Regex.match?(rfc3339_duration_regex(), data) do
        Duration.from_iso8601(data)
      else
        {:error, :invalid_format}
      end
    end
  end

  def validate_cast("time", data) do
    if full_time?(data) do
      Time.from_iso8601(String.upcase(data))
    else
      {:error, :invalid_format}
    end
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

  if @supports_duration do
    # On OTP 28+, a regex literal is imported again each time it is evaluated.
    @on_load :store_rfc3339_duration_regex

    # RFC 3339 Appendix A. Elixir's parser is more permissive: it accepts signs,
    # fractional components, a comma as the decimal separator, and mixing weeks
    # with other elements.
    defp store_rfc3339_duration_regex do
      :persistent_term.put(:jsv_formats_default_duration_re, ~r"""
      \AP(?:
        [0-9]+W
        | (?:[0-9]+Y(?:[0-9]+M(?:[0-9]+D)?)?|[0-9]+M(?:[0-9]+D)?|[0-9]+D)
          (?:T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S))?
        | T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S)
      )\z
      """x)
    end

    defp rfc3339_duration_regex do
      :persistent_term.get(:jsv_formats_default_duration_re)
    end
  end

  # RFC 3339 section 5.6. Elixir's parsers are more permissive: they accept
  # signed years, a leading "T" for times, a comma as the decimal separator,
  # truncated offsets such as "+01" or "+0130", and a space instead of "T".
  defp full_date?(<<y::binary-size(4), ?-, m::binary-size(2), ?-, d::binary-size(2)>>) do
    digits?(y) and digits?(m) and digits?(d)
  end

  defp full_date?(_) do
    false
  end

  defp full_time?(<<h::binary-size(2), ?:, m::binary-size(2), ?:, s::binary-size(2), rest::binary>>) do
    digits?(h) and digits?(m) and digits?(s) and decimal_part_and_offset?(rest)
  end

  defp full_time?(_) do
    false
  end

  defp decimal_part_and_offset?(<<?., c, rest::binary>>) when c in ?0..?9 do
    decimal_part_digits_and_offset?(rest)
  end

  defp decimal_part_and_offset?(rest) do
    time_offset?(rest)
  end

  defp decimal_part_digits_and_offset?(<<c, rest::binary>>) when c in ?0..?9 do
    decimal_part_digits_and_offset?(rest)
  end

  defp decimal_part_digits_and_offset?(rest) do
    time_offset?(rest)
  end

  defp time_offset?(<<z>>) when z in [?Z, ?z] do
    true
  end

  defp time_offset?(<<sign, h::binary-size(2), ?:, m::binary-size(2)>>) when sign in [?+, ?-] do
    digits?(h) and digits?(m)
  end

  defp time_offset?(_) do
    false
  end

  defp digits?(<<c, rest::binary>>) when c in ?0..?9 do
    digits?(rest)
  end

  defp digits?(<<>>) do
    true
  end

  defp digits?(_) do
    false
  end
end
