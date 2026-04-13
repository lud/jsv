# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
defmodule Mix.Tasks.Jsv.GenTestSuite do
  alias CliMate.CLI
  alias JSV.Helpers.Traverse
  require EEx
  use Mix.Task

  @shortdoc "Regenerate the JSON Schema Test Suite"

  @root_suites_dir Path.join([File.cwd!(), "deps", "json_schema_test_suite", "tests"])

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
      ignore: [
        "weeks cannot be combined with other units",
        "hours and seconds cannot appear without minutes",
        "years and days cannot appear without months",
        "fractional duration is not allowed by RFC 3339 ABNF"
      ],
      elixir: "~> 1.17"
    ],
    "optional/format/uuid.json" => [schema_build_opts: [formats: true]],

    # Unsupported

    "optional/format/ecmascript-regex.json" => :unsupported
  }

  @enabled_specific_7 %{
    "additionalItems.json" => [],
    "definitions.json" => [],
    "dependencies.json" => [],

    # Unsupported

    "optional/content.json" => :unsupported
  }

  @enabled_common %{
    "additionalProperties.json" => [
      atom_ignore: [
        # Those tests use regexes in pattern properties. We do not want to
        # render those as atoms as it will be confusing.
        "additionalProperties being false does not allow other properties",
        "non-ASCII pattern with additionalProperties"
      ]
    ],
    "allOf.json" => [],
    "anyOf.json" => [],
    "boolean_schema.json" => [],
    "const.json" => [decimal_ignore: true],
    "contains.json" => [],
    "default.json" => [],
    "enum.json" => [decimal_ignore: true],
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
    "pattern.json" => [
      ignore: [
        # Invalid regex for elixir
        "pattern with Unicode property escape requires unicode mode"
      ]
    ],
    "patternProperties.json" => [
      ignore: [
        # Invalid regex for elixir
        "patternProperties with Unicode property escape"
      ]
    ],
    "properties.json" => [],
    "propertyNames.json" => [],
    "ref.json" => [],
    "refRemote.json" => [],
    "required.json" => [],
    "type.json" => [],
    "uniqueItems.json" => [decimal_ignore: true],

    # Optional

    "optional/bignum.json" => [],
    "optional/id.json" => [],

    # Formats

    "optional/format/date.json" => [schema_build_opts: [formats: true]],
    "optional/format/email.json" => [schema_build_opts: [formats: true]],
    "optional/format/hostname.json" => [
      schema_build_opts: [formats: true],
      ignore: [
        "exceeds maximum label length",
        "a host name with a component too long"
      ]
    ],
    "optional/format/ipv4.json" => [schema_build_opts: [formats: true]],
    "optional/format/ipv6.json" => [schema_build_opts: [formats: true]],
    "optional/format/iri-reference.json" => [schema_build_opts: [formats: true]],
    "optional/format/iri.json" => [schema_build_opts: [formats: true]],
    "optional/format/json-pointer.json" => [schema_build_opts: [formats: true]],
    "optional/format/regex.json" => [schema_build_opts: [formats: true]],
    "optional/format/relative-json-pointer.json" => [schema_build_opts: [formats: true]],
    "optional/format/unknown.json" => [schema_build_opts: [formats: true]],
    "optional/format/uri-reference.json" => [schema_build_opts: [formats: true]],
    "optional/format/uri-template.json" => [schema_build_opts: [formats: true]],
    "optional/format/uri.json" => [
      schema_build_opts: [formats: true],
      ignore: [
        # LDAP URL with IPv6 and ?-separated query fields – valid URI but rejected by Erlang's uri_string
        "a valid URL"
      ]
    ],
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
        "only RFC3339 not all of ISO 8601 are valid",

        # Elixir does not support RFC 3339 §4.3 "-00:00" unknown local offset
        "time with unknown local offset is valid"
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
    "optional/unknownKeyword.json" => :unsupported,

    # Unsupported

    "optional/format/idn-email.json" => :unsupported,
    "optional/format/idn-hostname.json" => :unsupported,
    "optional/ecmascript-regex.json" => :unsupported,
    "optional/float-overflow.json" => :unsupported,
    "optional/non-bmp-regex.json" => :unsupported
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

  @test_suites %{
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

        describe <%= inspect(tcase.description) %> do

          setup do
            json_schema = <%= render_ordered_schema(tcase.schema, @suite_flavor) %>
            schema = JsonSchemaSuite.build_schema(json_schema, <%= inspect(@schema_build_opts, limit: :infinity, pretty: true) %>)
            {:ok, json_schema: json_schema, schema: schema}
          end

          <%= for ttest <- tcase.tests do %>

            <%= if not ttest.skip? do %>
            test <%= inspect(ttest.description) %>, x do
              data = <%= render_test_data(ttest.data, @suite_flavor) %>
              expected_valid = <%= inspect(ttest.valid?) %>
              JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
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

    # Generate default JSON schemas
    do_run(suite, :default)

    # Generate tests using %JSV.Schema{} structs for any compatible map.
    do_run(suite, :jsv_schema_structs)

    # Generate tests where data can contain Decimal structs (but not schemas)
    do_run(suite, :decimal_test_data)

    Mix.start()
    Mix.Task.run("format", ["--migrate"])
  end

  # Format can be :binary or :atom, it changes the way the schemas will be
  # represented in the tests
  defp do_run(suite_name, suite_flavor, max_tests \\ :infinity) do
    subnamespace =
      case suite_flavor do
        :default -> "BinaryKeys"
        :jsv_schema_structs -> "AtomKeys"
        :decimal_test_data -> "DecimalValues"
      end

    suite_ns = String.replace(suite_name, "-", "")
    namespace = Module.concat([JSV, Generated, Macro.camelize(suite_ns), subnamespace])
    test_directory = namespace |> preferred_path() |> String.replace(~r/\.ex$/, "")

    CLI.warn("Deleting current test files directory #{test_directory}")
    _ = File.rm_rf!(test_directory)

    test_suite =
      case Map.fetch(@test_suites, suite_name) do
        {:ok, map} when is_map(map) -> map
        :error -> raise ArgumentError, "No suite configuration for #{inspect(suite_name)}"
      end

    schema_options = [default_meta: default_meta(suite_name)]

    test_suite
    |> stream_cases(suite_name, suite_flavor)
    |> take_max_tests(max_tests)
    |> Stream.map(&gen_test_mod(&1, namespace, suite_flavor, schema_options))
    |> Enum.count()
    |> then(&IO.puts("Wrote #{&1} files"))
  end

  defp take_max_tests(stream, :infinity) do
    stream
  end

  defp take_max_tests(stream, n) do
    Stream.take(stream, n)
  end

  defp default_meta("draft7") do
    "http://json-schema.org/draft-07/schema"
  end

  defp default_meta("draft2020-12") do
    "https://json-schema.org/draft/2020-12/schema"
  end

  def stream_cases(enabled_cases, suite_name, suite_flavor) do
    suite_dir = suite_dir!(suite_name)

    suite_dir
    |> Path.join("**/**.json")
    |> Path.wildcard()
    |> Enum.sort()
    |> Stream.transform(
      fn -> {_discarded = [], enabled_cases} end,
      fn path, {discarded, enabled} ->
        rel_path = Path.relative_to(path, suite_dir)

        # We delete the {file, opts} entry in the enabled map when we use it, so
        # we can print unexpected configs (useful when the JSON schema test
        # suite maintainers delete some test files).

        case Map.pop(enabled, rel_path, :error) do
          {:unsupported, rest_enabled} -> {[], {discarded, rest_enabled}}
          {:error, ^enabled} -> {[], {[rel_path | discarded], enabled}}
          {opts, rest_enabled} -> {[%{path: path, rel_path: rel_path, opts: opts}], {discarded, rest_enabled}}
        end
      end,
      fn {discarded, rest_enabled} ->
        # Cases found in the JSON files that were not declared, and so not
        # returned in the stream
        print_unchecked(suite_name, discarded)

        # Cases configured in `all_enabled` that were not found as JSON files.
        print_unexpected(suite_name, rest_enabled)
      end
    )
    |> Stream.flat_map(fn item ->
      %{path: path, opts: opts} = item

      case marshall_file(path, suite_flavor, opts) do
        [] -> []
        test_cases -> [Map.put(item, :test_cases, test_cases)]
      end
    end)
  end

  defp marshall_file(source_path, suite_flavor, opts) do
    ignore = Keyword.get(opts, :ignore, [])

    ignore =
      if suite_flavor == :jsv_schema_structs do
        Keyword.get(opts, :atom_ignore, []) ++ ignore
      else
        ignore
      end

    {ignore, ignore_all?} =
      if suite_flavor == :decimal_test_data do
        case Keyword.get(opts, :decimal_ignore) do
          nil -> {ignore, false}
          true -> {ignore, true}
        end
      else
        {ignore, false}
      end

    if ignore_all? do
      []
    else
      elixir = Keyword.get(opts, :elixir, nil)
      do_marshall_file(source_path, suite_flavor, ignore, elixir)
    end
  end

  defp do_marshall_file(source_path, suite_flavor, ignore, elixir) do
    source_path
    |> File.read!()
    |> Jason.decode!(floats: :decimals)
    |> Enum.flat_map(fn tcase ->
      %{"description" => tc_descr, "schema" => schema, "tests" => tests} = tcase
      tcase_ignored = tc_descr in ignore

      tests =
        Enum.map(tests, fn ttest ->
          %{"description" => tt_descr, "data" => data, "valid" => valid} = ttest

          ttest_ignored = tt_descr in ignore

          %{
            description: tt_descr,
            data: data,
            valid?: valid,
            skip?: ttest_ignored or tcase_ignored,
            ignore: ignore
          }
        end)

      # For the :decimal_test_data flavor we will only generate tests that do
      # have a Decimal struct in the test data
      tests =
        if suite_flavor == :decimal_test_data do
          mark_skip_tests_without_decimal_test_data(tests)
        else
          tests
        end

      all_ignored? = Enum.all?(tests, & &1.skip?)

      if all_ignored? do
        []
      else
        [%{description: tc_descr, schema: schema, tests: tests, elixir_version_check: elixir}]
      end
    end)
  end

  defp mark_skip_tests_without_decimal_test_data(tests) do
    Enum.map(
      tests,
      fn
        %{skip?: true} = already_skipped ->
          already_skipped

        test ->
          if contains_decimal_struct?(test) do
            test
          else
            %{test | skip?: true}
          end
      end
    )
  end

  defp contains_decimal_struct?(data) do
    Traverse.postwalk(data, fn
      {:struct, %Decimal{}, _} -> throw(:contains_decimal)
      other -> elem(other, 1)
    end)

    false
  catch
    :contains_decimal -> true
  end

  def suite_dir!(suite) do
    path = Path.join(@root_suites_dir, suite)

    case File.dir?(path) do
      true -> path
      false -> raise ArgumentError, "unknown suite #{suite}, could not find directory #{path}"
    end
  end

  defp print_unchecked(suite, []) do
    IO.puts("All cases checked out for #{suite}")
  end

  defp print_unchecked(suite, paths) do
    total = length(paths)
    maxprint = 20
    more? = total > maxprint

    print_list =
      paths
      |> Enum.sort_by(fn
        "optional/format/" <> _ = rel_path -> {2, rel_path}
        "optional/" <> _ = rel_path -> {1, rel_path}
        rel_path -> {0, rel_path}
      end)
      |> Enum.take(maxprint)
      |> Enum.map_intersperse(?\n, fn filename -> "{#{inspect(filename)}, []}," end)

    IO.warn(
      """
      Unchecked test cases in #{suite}:
      #{print_list}
      #{(more? && "... (#{total - maxprint} more)") || ""}
      """,
      []
    )
  end

  defp print_unexpected(_suite, map) when map_size(map) == 0 do
    # no noise
  end

  defp print_unexpected(suite, map) do
    IO.warn(
      """
      Unexpected test cases in #{suite}:
      #{map |> Map.to_list() |> Enum.map_join("\n", &inspect/1)}
      """,
      []
    )
  end

  defp gen_test_mod(mod_info, namespace, suite_flavor, schema_options) do
    module_name = module_name(mod_info, namespace)

    case_build_opts = get_in(mod_info, [:opts, :schema_build_opts]) || []
    schema_build_opts = Keyword.merge(schema_options, case_build_opts)

    assigns =
      Map.merge(mod_info, %{module_name: module_name, schema_build_opts: schema_build_opts, suite_flavor: suite_flavor})

    module_contents = module_template(assigns)
    module_path = module_path(module_name)

    File.mkdir_p!(Path.dirname(module_path))
    File.write!(module_path, module_contents, [:sync])
    module_path
  end

  defp module_path(module_name) do
    path = preferred_path(module_name)
    mod_path = Regex.replace(~r/\.ex$/, path, ".exs")
    true = String.ends_with?(mod_path, ".exs")
    mod_path
  end

  defp preferred_path(module_name) do
    mount = Modkit.Mount.define!([{JSV.Generated, "test/jsv/generated"}])
    {:ok, path} = Modkit.Mount.preferred_path(mount, module_name)
    path
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

  defp render_ordered_schema(schema, suite_flavor) when is_map(schema) do
    # For all flavors the wrapper will render the keys in a preferred order.

    # For now we support Decimal in data but not in the schema, so here it is
    # always a float.

    schema =
      Traverse.postwalk(schema, fn
        {:struct, %Decimal{} = d, _} -> Decimal.to_float(d)
        {:val, value} when is_map(value) -> __MODULE__.ValueDumper.wrap(value, suite_flavor)
        {_, x} -> x
      end)

    inspect(schema, pretty: true, limit: :infinity, printable_limit: :infinity)
  end

  defp render_ordered_schema(schema, _) when is_boolean(schema) do
    inspect(schema, pretty: true, limit: :infinity, printable_limit: :infinity)
  end

  defp render_test_data(data, suite_flavor) do
    # Using the inspect protocol, depending on the flavor we will render the
    # data differently.
    #
    # The data parsed from the test suite already contains Decimal structs
    # instead of floats
    #
    # * For :decimal_test_data we will inspect the Decimal struct as-is, which
    #   outputs a `Decimal.new("...")` call
    # * For other flavors we will render the data as a a float.

    data =
      case suite_flavor do
        :decimal_test_data ->
          data

        _ ->
          Traverse.postwalk(data, fn
            {:struct, %Decimal{} = d, _} -> __MODULE__.ValueDumper.wrap(d, suite_flavor)
            {_, x} -> x
          end)
      end

    inspect(data, pretty: true, limit: :infinity, printable_limit: :infinity)
  end

  defmodule ValueDumper do
    import Inspect.Algebra

    @key_order [
                 # metada of the schema
                 "$schema",
                 "$id",
                 "$anchor",
                 "$dynamicAnchor",

                 # text headers
                 "title",
                 "description",
                 "comment",

                 # collection of other schemas
                 "definitions",
                 "$defs",

                 # references to other schemas
                 "$dynamicRef",
                 "$ref",

                 # validations

                 # type should be the first validation
                 "type",

                 # properties should be ordered like so, with required afterwards
                 "properties",
                 "patternProperties",
                 "additionalProperties",
                 "required"
               ]
               |> Enum.with_index()
               |> Map.new()

    @schema_struct_keys Map.keys(Map.from_struct(JSV.Schema.__struct__()))

    defstruct value: [], suite_flavor: nil

    def wrap(value, suite_flavor) do
      %__MODULE__{value: value, suite_flavor: suite_flavor}
    end

    def render(%{value: %Decimal{}, suite_flavor: :decimal_test_data}, _) do
      # For :decimal_test_data flavor the Decimal structs in the test data are
      # not wrapped.
      raise "should not happen"
    end

    # Render normal floats
    def render(%{value: %Decimal{} = d}, _) do
      # We return the decimal as a string, but as we are implementing the
      # inspect protocol this will be a float in the generated test module.
      Decimal.to_string(d)
    end

    # Render JSV.Schema structs or maps with atom keys
    def render(%{value: map, suite_flavor: :jsv_schema_structs}, inspect_opts)
        when is_map(map) and not is_struct(map) do
      # Map keys in schemas are always binaries

      # Turn the map into a list ordered by key_order
      list = to_ordlist(map)

      # Force cast all keys as atoms
      list = Enum.map(list, fn {k, v} -> {String.to_atom(k), v} end)

      # Inner map is a keyword
      fun = &Inspect.List.keyword/2

      schema_struct_compatible? = Enum.all?(list, fn {k, _} -> k in @schema_struct_keys end)

      struct_name =
        if schema_struct_compatible? do
          "JSV.Schema"
        else
          ""
        end

      map_container_doc(list, struct_name, inspect_opts, fun)
    end

    # # Render maps with binary keys
    def render(%{value: map, suite_flavor: _other_flavors}, inspect_opts)
        when is_map(map) and not is_struct(map) do
      # Map keys in schemas are always binaries

      # Turn the map into a list ordered by key_order
      list = to_ordlist(map)

      # Inner map render
      fun = &to_assoc(&1, &2, " => ")

      struct_name = ""

      map_container_doc(list, struct_name, inspect_opts, fun)
    end

    defp to_assoc({key, value}, opts, sep) do
      concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
    end

    defp map_container_doc(list, name, opts, fun) do
      open = "%" <> name <> "{"
      sep = ","
      close = "}"
      container_doc(open, list, close, opts, fun, separator: sep, break: :strict)
    end

    def to_ordlist(map) do
      map
      |> Map.to_list()
      |> Enum.sort_by(fn {k, _} -> order_of(k) end)
    end

    defp order_of(key) when is_binary(key) do
      case Map.fetch(@key_order, key) do
        {:ok, order} -> {0, order}
        :error -> {1, key}
      end
    end
  end
end

defimpl Inspect, for: Mix.Tasks.Jsv.GenTestSuite.ValueDumper do
  def inspect(dumper, opts) do
    Mix.Tasks.Jsv.GenTestSuite.ValueDumper.render(dumper, opts)
  end
end
