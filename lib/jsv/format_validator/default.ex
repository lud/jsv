defmodule JSV.FormatValidator.Default.Optional do
  @moduledoc false
  def optional_support(format, supported?) when is_boolean(supported?) do
    if supported? do
      List.wrap(format)
    else
      []
    end
  end

  def mod_exists?(module) do
    case Code.ensure_loaded(module) do
      {:module, ^module} -> true
      {:error, _} -> false
    end
  end
end

defmodule JSV.FormatValidator.Default do
  import JSV.FormatValidator.Default.Optional, only: [mod_exists?: 1, optional_support: 2]
  alias JSV.FormatValidator.Default.Optional

  @behaviour JSV.FormatValidator

  # TODO document that missing implementations can be added by users.

  # TODO document the fact that support for durations is since elixir 1.17.

  # TODO document that (per the docs): Only seconds may be specified with a
  # decimal fraction, using either a comma or a full stop: P1DT4,5S.

  # TODO document that Duration will accept negative values.

  # TODO document that Duration will accept large values, like more than 59 minutes.

  # TODO document support for email using mail_address optional dependency and
  # limited by that implementation.

  # TODO document idn-email not supported, and email with limited support.

  # TODO document uri / uri-reference fallback is very permissive if abnf_parsec
  # is not defined:
  # * uri will only check for scheme and host presence
  # * document uri-reference is very permissive and will turn most strings into
  #   a single path

  # TODO document optional libraries
  # - {:mail_address, "~> 1.0", optional: true},
  # - {:abnf_parsec, "~> 1.0", runtime: false, optional: true},

  # TODO document that date-time and time will accept arbitrary precision
  # instead of milliseconds, like in "2024-12-14T23:10:00.50000000000000000001Z"

  # TODO document that time discards the time offset completely

  # TODO document that date does only support the YYYY-MM-DD format, and not
  # 2024, 2024-W50, 2024-12, etc.

  # TODO document that regexes are compiled with the Elixir `Regex` module and
  # not according to ECMA-262

  @supports_duration mod_exists?(Duration)
  @supports_email mod_exists?(MailAddress.Parser)
  @supports_iri mod_exists?(AbnfParsec)
  @supports_uri_template mod_exists?(AbnfParsec)
  @supports_json_pointer mod_exists?(AbnfParsec)

  # TODO document hostname accepts numerical TLDs and single letter TLDs

  @re_hostname ~r/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/

  @formats [
             optional_support("duration", @supports_duration),
             optional_support("email", @supports_email),
             optional_support("iri", @supports_iri),
             optional_support("iri-reference", @supports_iri),
             optional_support("uri-template", @supports_uri_template),
             optional_support(["json-pointer", "relative-json-pointer"], @supports_json_pointer),
             [
               "ipv4",
               "ipv6",
               "unknown",
               "regex",
               "date",
               "date-time",
               "time",
               "email",
               "hostname",
               "uri",
               "uri-reference",
               "uuid"
             ]
           ]
           |> :lists.flatten()

  def supported_formats do
    @formats
  end

  def validate_cast("date-time", data) do
    case DateTime.from_iso8601(data) do
      {:ok, dt, _} ->
        if String.contains?(data, " ") do
          {:error, :invalid_format}
        else
          {:ok, dt}
        end

      {:error, _} = err ->
        err
    end
  end

  def validate_cast("date", data) do
    Date.from_iso8601(data)
  end

  if @supports_duration do
    def validate_cast("duration", data) do
      # JSON schema adheres closely to the spec, the duration cannot mix Week and
      # other P-level elements. But we are allowing it because Elixir allows it,
      # we do not want to put arbitrary limit to capabilities.
      Duration.from_iso8601(data)
    end
  end

  def validate_cast("time", data) do
    Time.from_iso8601(String.replace(data, "z", "Z"))
  end

  def validate_cast("ipv4", data) do
    :inet.parse_strict_address(String.to_charlist(data))
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

  if @supports_email do
    def validate_cast("email", data) do
      if MailAddress.Parser.valid?(data) do
        {:ok, data}
      else
        {:error, :invalid_email}
      end
    end
  end

  def validate_cast("hostname", data) do
    if Regex.match?(@re_hostname, data) do
      {:ok, data}
    else
      {:error, :invalid_hostname}
    end
  end

  def validate_cast("iri", data) do
    Optional.IRI.parse_iri(data)
  end

  def validate_cast("iri-reference", data) do
    Optional.IRI.parse_iri_reference(data)
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
    Optional.URITemplate.parse_uri_template(data)
  end

  def validate_cast("json-pointer", data) do
    Optional.JSONPointer.parse_json_pointer(data)
  end

  def validate_cast("relative-json-pointer", data) do
    Optional.JSONPointer.parse_relative_json_pointer(data)
  end
end
