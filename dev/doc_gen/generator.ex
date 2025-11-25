if Code.ensure_loaded?(Readmix.Generator) do
  defmodule JSV.DocGen.Generator do
    use Readmix.Generator

    @moduledoc false

    action :formats, params: []

    abnf_req = "Depends on `:abnf_parsec` (automatically included)"
    texture = "Depends on `:texture` (automatically included)"
    idna = "Depends on `:idna` (automatically included)"

    @formats_specs %{
      "date" => %{
        input: "2020-04-22",
        native: Date,
        notes: [
          "The native `Date` module supports the `YYYY-MM-DD` format only. `2024`, `2024-W50`, `2024-12` will not be valid."
        ]
      },
      "date-time" => %{
        input: "2025-01-02T00:11:23.416689Z",
        native: DateTime,
        notes: [
          "The native `DateTime` module supports the `YYYY-MM-DD` format only for dates. `2024T...`, `2024-W50T...`, `2024-12T...` will not be valid.",
          "Decimal precision is not capped to milliseconds. `2024-12-14T23:10:00.500000001Z` will be valid."
        ]
      },
      "duration" => %{
        input: "P1DT4,5S",
        support: "Requires Elixir 1.17",
        native: Duration,
        notes: [
          "Elixir documentation states that _Only seconds may be specified with a decimal fraction, using either a comma or a full stop: P1DT4,5S_.",
          "Elixir durations accept negative values.",
          "Elixir durations accept out-of-range values, for instance more than 59 minutes.",
          ~s[Excessive precision (as in `"PT10.0000000000001S"`) will be valid.]
        ]
      },
      "email" => %{
        input: "hello@json-schema.org",
        support: abnf_req,
        notes: [
          "Support is limited by the implementation of that library.",
          "The `idn-email` format is not supported out-of-the-box."
        ]
      },
      "hostname" => %{
        input: "xn--zca29lwxobi7a",
        support: idna
      },
      "ipv4" => %{
        input: "127.0.0.1",
        native: :inet
      },
      "ipv6" => %{
        input: "::1",
        native: :inet
      },
      "iri" => %{
        input: "https://héhé.com/héhé",
        support: abnf_req
      },
      "iri-reference" => %{
        input: "//héhé",
        support: abnf_req
      },
      "json-pointer" => %{
        input: "/foo/bar/baz",
        support: abnf_req
      },
      "relative-json-pointer" => %{
        input: "0/foo/bar",
        support: abnf_req
      },
      "regex" => %{
        input: "[a-zA-Z0-9]",
        native: Regex,
        notes: [
          "The `Regex` module does not follow the `ECMA-262` specification."
        ]
      },
      "time" => %{
        input: "20:20:08.378586",
        native: Time,
        notes: [
          "The native `Time` implementation will completely discard the time offset information. Invalid offsets will be valid.",
          "Decimal precision is not capped to milliseconds. `23:10:00.500000001` will be valid."
        ]
      },
      "unknown" => %{
        input: "anything",
        support: "Native",
        notes: ["No validation or transformation is done."]
      },
      "uri" => %{
        input: "http://example.com",
        native: URI,
        support: abnf_req,
        notes: [
          "Without the optional dependency, the `URI` module is used and a minimum checks on hostname and scheme presence are made."
        ]
      },
      "uri-reference" => %{
        input: "/example-path",
        native: URI,
        support: abnf_req,
        notes: [
          "Without the optional dependency, the `URI` module will cast most non url-like strings as a `path`."
        ]
      },
      "uri-template" => %{
        input: "http://example.com/search{?query,lang}",
        support: texture,
        custom_output: "%Texture.UriTemplate{}"
      },
      "uuid" => %{
        input: "bf22824c-c8a4-11ef-9642-0fdaf117eeb9",
        support: "Native"
      }
    }

    defp formats_specs do
      @formats_specs
    end

    @spec formats(term, term) :: {:ok, iodata()}
    def formats(_, _) do
      generated =
        JSV.FormatValidator.Default.supported_formats()
        |> Enum.sort()
        |> Enum.map(&render_format/1)

      {:ok, generated}
    end

    defp render_format(format) do
      schema = JSV.build!(%{format: format}, formats: true)

      spec = Map.fetch!(formats_specs(), format)
      input = Map.fetch!(spec, :input)
      notes = Map.get(spec, :notes, [])
      custom_output = Map.get(spec, :custom_output, nil)

      {support, notes} =
        case spec do
          %{native: module, support: support} ->
            {support, ["The format is implemented with the native `#{inspect(module)}` module." | notes]}

          %{native: module} ->
            {"Native.", ["The format is implemented with the native `#{inspect(module)}` module." | notes]}

          %{support: support} ->
            {support, notes}
        end

      {:ok, casted} = JSV.validate(input, schema, cast_formats: true)

      support =
        case support do
          b when is_binary(b) -> b
          {lib, version} -> "Requires `#{inspect({lib, version})}`."
        end

      output =
        case {casted, custom_output} do
          {^input, nil} -> "Input value."
          {_, nil} -> "`#{inspect(casted)}`"
          {_, custom} -> "`#{custom}`"
        end

      _wrapped =
        """
        ### #{format}

        * **support**: #{support}
        * **input**: `#{inspect(input)}`
        * **output**: #{output}
        #{Enum.map(notes, &["* ", &1, "\n"])}
        """
    end
  end
end
