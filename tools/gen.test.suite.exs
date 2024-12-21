defmodule GenTestSuite do
  alias CliMate.CLI
  alias JSV.JsonTools
  alias JSV.Test.JsonSchemaSuite
  require EEx

  @enabled_specific_202012 %{
    "anchor.json" => [],
    "content.json" => [],
    "defs.json" => [],
    "dependentRequired.json" => [],
    "dependentSchemas.json" => [],
    "dynamicRef.json" => [],
    "maxContains.json" => [],
    "minContains.json" => [],
    "prefixItems.json" => [],
    "unevaluatedItems.json" => [],
    "unevaluatedProperties.json" => [],
    "vocabulary.json" => [],

    # Optional

    "optional/anchor.json" => [],
    "optional/no-schema.json" => [],
    "optional/dependencies-compatibility.json" => [],
    "optional/dynamicRef.json" => [],
    "optional/refOfUnknownKeyword.json" => [],

    # Formats

    "optional/format-assertion.json" => [],
    "optional/format/duration.json" => [
      schema_build_opts: [formats: true],
      ignore: ["weeks cannot be combined with other units"],
      elixir: "~> 1.17"
    ],
    "optional/format/uuid.json" => :unsupported,
    "optional/format/ecmascript-regex.json" => :unsupported
  }

  @enabled_specific_7 %{
    "additionalItems.json" => [],
    "definitions.json" => [],
    "dependencies.json" => [],
    # Optional
    "optional/content.json" => :unsupported
  }

  @enabled_common %{
    "additionalProperties.json" => [],
    "allOf.json" => [],
    "anyOf.json" => [],
    "boolean_schema.json" => [],
    "const.json" => [],
    "contains.json" => [],
    "default.json" => [],
    "enum.json" => [],
    "exclusiveMaximum.json" => [],
    "exclusiveMinimum.json" => [],
    "format.json" => [],
    "if-then-else.json" => [],
    "infinite-loop-detection.json" => [],
    "items.json" => [],
    "maximum.json" => [],
    "maxItems.json" => [],
    "maxLength.json" => [],
    "maxProperties.json" => [],
    "minimum.json" => [],
    "minItems.json" => [],
    "minLength.json" => [],
    "minProperties.json" => [],
    "multipleOf.json" => [],
    "not.json" => [],
    "oneOf.json" => [],
    "pattern.json" => [],
    "patternProperties.json" => [],
    "properties.json" => [],
    "propertyNames.json" => [],
    "ref.json" => [],
    "refRemote.json" => [],
    "required.json" => [],
    "type.json" => [],
    "uniqueItems.json" => [],

    # Optional

    "optional/bignum.json" => [],
    "optional/ecmascript-regex.json" => :unsupported,
    "optional/float-overflow.json" => :unsupported,
    "optional/id.json" => [],
    "optional/non-bmp-regex.json" => :unsupported,

    # Formats

    "optional/format/date.json" => [schema_build_opts: [formats: true]],
    "optional/format/email.json" => :unsupported,
    "optional/format/hostname.json" => :unsupported,
    "optional/format/idn-email.json" => :unsupported,
    "optional/format/idn-hostname.json" => :unsupported,
    "optional/format/ipv4.json" => [schema_build_opts: [formats: true]],
    "optional/format/ipv6.json" => [schema_build_opts: [formats: true]],
    "optional/format/iri-reference.json" => :unsupported,
    "optional/format/iri.json" => :unsupported,
    "optional/format/json-pointer.json" => :unsupported,
    "optional/format/regex.json" => [schema_build_opts: [formats: true]],
    "optional/format/relative-json-pointer.json" => :unsupported,
    "optional/format/unknown.json" => [schema_build_opts: [formats: true]],
    "optional/format/uri-reference.json" => :unsupported,
    "optional/format/uri-template.json" => :unsupported,
    "optional/format/uri.json" => :unsupported,
    "optional/format/time.json" => [
      schema_build_opts: [formats: true],
      ignore: [
        # Elixir built-in calendar does not support leap seconds
        "valid leap second, large positive time-offset",
        "valid leap second, positive time-offset",
        "valid leap second, zero time-offset",
        "valid leap second, large negative time-offset",
        "a valid time string with leap second, Zulu",
        "valid leap second, negative time-offset",

        # Elixir does not require a time offset to be set
        "no time offset",
        "no time offset with second fraction",

        # Elixir supports more formats that RFC3339
        "only RFC3339 not all of ISO 8601 are valid"
      ]
    ],
    "optional/format/date-time.json" => [
      schema_build_opts: [formats: true],
      ignore: [
        "case-insensitive T and Z",
        "a valid date-time with a leap second, UTC",
        "a valid date-time with a leap second, with minus offset"
      ]
    ],

    # Architecture problems

    # Uses schema 2019 in tests which we do not support
    "optional/cross-draft.json" => :unsupported,

    # We need to make a change so each vocabulary module exports a strict list
    # of supported keywords, and the resolver schema scanner does not
    # automatically build schemas under unknown keywords.
    #
    # Another problem is that we need to convert the raw schemas to know if it
    # is a sub schema is a real schema or an object that contains "$id" but is
    # not under a supported keyword. For that we should traverse the whole
    # schema and tag the "real" schemas we find, and then when a path points to
    # a definition with "$id" inside we check if the tag is present, or we
    # disregard that "$id".
    "optional/unknownKeyword.json" => :unsupported
  }

  raise_same_key = fn k, v1, v2 ->
    raise ArgumentError, """
    duplicate definition for test #{inspect(k)}

    COMMON
    #{inspect(v1)}

    SPECIFIC
    #{inspect(v2)}

    """
  end

  @enabled %{
    "draft2020-12" => Map.merge(@enabled_common, @enabled_specific_202012, raise_same_key),
    "draft7" => Map.merge(@enabled_common, @enabled_specific_7, raise_same_key)
  }

  @command [
    module: __MODULE__,
    arguments: [
      suite: [
        type: :string,
        short: :s,
        doc: """
        The json test suite in 'draft2019-09', 'draft2020-12', 'draft3', 'draft4',
        'draft6', 'draft7', 'draft-next' or 'latest'.
        """
      ]
    ],
    options: []
  ]

  EEx.function_from_string(
    :defp,
    :module_template,
    ~S"""
    # credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
    # credo:disable-for-this-file Credo.Check.Readability.StringSigils

    defmodule <%= inspect(@module_name) %> do
      alias JSV.Test.JsonSchemaSuite
      use ExUnit.Case, async: true

      @moduledoc \"""
      Test generated from <%= Path.relative_to_cwd(@path) %>
      \"""

      <%= for tcase <- @test_cases do %>

        <%= if tcase.elixir_version_check do %>
          if JsonSchemaSuite.version_check(<%= inspect(tcase.elixir_version_check) %>) do
        <% end %>

        describe <%= inspect(tcase.description <> ":") %> do

          setup do

            json_schema = Jason.decode!(<%= decoding_schema(tcase.schema) %>)
            schema = JsonSchemaSuite.build_schema(json_schema, <%= inspect(@schema_build_opts, limit: :infinity, pretty: true) %>)
            {:ok, json_schema: json_schema, schema: schema}
          end

          <%= for ttest <- tcase.tests do %>
            <%= if not ttest.skip? do %>
            test <%= inspect(ttest.description) %>, c do
              data = <%= inspect(ttest.data, limit: :infinity, pretty: true) %>
              expected_valid = <%= inspect(ttest.valid?) %>
              JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
            end
            <% end %>
          <% end %>
        end

        <%= if tcase.elixir_version_check do %>
          end
        <% end %>

      <% end %>
    end
    """,
    [
      :assigns
    ]
  )

  def run(argv) do
    %{options: _options, arguments: %{suite: suite}} = CLI.parse_or_halt!(argv, @command)

    do_run(suite)
    Mix.Task.run("format")
  end

  defp do_run(suite) do
    test_directory = "test/generated/#{suite}"
    namespace = Module.concat([JSV, Generated, Macro.camelize(String.replace(suite, "-", ""))])

    CLI.warn("Deleting current test files directory #{test_directory}")
    _ = File.rm_rf!(test_directory)

    enabled =
      case Map.fetch(@enabled, suite) do
        {:ok, false} -> Map.new([])
        {:ok, map} when is_map(map) -> map
        :error -> raise ArgumentError, "No suite configuration for #{inspect(suite)}"
      end

    schema_options = [default_meta: default_meta(suite)]

    suite
    |> JsonSchemaSuite.stream_cases(enabled)
    |> Stream.map(&gen_test_mod(&1, test_directory, namespace, schema_options))
    |> Enum.count()
    |> then(&IO.puts("Wrote #{&1} files"))
  end

  defp default_meta("draft7") do
    "http://json-schema.org/draft-07/schema"
  end

  defp default_meta("draft2020-12") do
    "https://json-schema.org/draft/2020-12/schema"
  end

  defp gen_test_mod(mod_info, test_directory, namespace, schema_options) do
    module_name = module_name(mod_info, namespace)

    case_build_opts = get_in(mod_info, [:opts, :schema_build_opts]) || []
    schema_build_opts = Keyword.merge(schema_options, case_build_opts)

    assigns = Map.merge(mod_info, %{module_name: module_name, schema_build_opts: schema_build_opts})

    module_contents = module_template(assigns)
    module_path = module_path(test_directory, namespace, module_name)

    File.mkdir_p!(Path.dirname(module_path))
    File.write!(module_path, module_contents)
  end

  @re_modpath ~r/\.ex$/

  defp module_path(test_directory, namespace, module_name) do
    mount = Modkit.Mount.define!([{namespace, test_directory}])
    {:ok, path} = Modkit.Mount.preferred_path(mount, module_name)

    mod_path = Regex.replace(@re_modpath, path, ".exs")
    true = String.ends_with?(mod_path, ".exs")
    mod_path
  end

  defp module_name(mod_info, namespace) do
    mod_name =
      mod_info.rel_path
      |> String.replace("optional/", "optional.")
      |> Path.basename(".json")
      |> Macro.underscore()
      |> String.replace(~r/[^A-Za-z0-9.\/]/, "_")
      |> Macro.camelize()
      |> Kernel.<>("Test")

    module = Module.concat(namespace, mod_name)

    case inspect(module) do
      ~s(:"Elixir) <> _ -> raise "invalid module: #{inspect(module)}"
      _ -> module
    end
  end

  @key_order ~w(
    $schema
    $id
    comment
    $defs
    definitions
    type
  ) |> Enum.with_index() |> Map.new()

  defp decoding_schema(data) do
    # return a string enclosed with triple double quotes without indentation.
    # Using sigil ~S to allow UTF-8 escape sequences.
    inner =
      JsonTools.encode_ordered!(
        data,
        fn {k, _} ->
          order = Map.get(@key_order, k, 999_999)
          {order, k}
        end,
        pretty: true
      )

    [~c'\n~S"""\n', inner, ~c'\n"""\n']
  end
end

GenTestSuite.run(System.argv())
