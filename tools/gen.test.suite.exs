defmodule JSV.GenTestSuite do
  alias CliMate.CLI
  alias JSV.JsonTools
  alias JSV.Test.JsonSchemaSuite
  require EEx

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
    "additionalProperties.json" => [
      atom_ignore: [
        # those tests use regexes in pattern properties.
        "additionalProperties being false does not allow other properties",
        "non-ASCII pattern with additionalProperties"
      ]
    ],
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

        describe <%= inspect(tcase.description) %> do

          setup do
            json_schema = <%= render_ordered_schema(tcase.schema, @keys_format) %>
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

    do_run(suite, :binary)
    do_run(suite, :atom, 1)
    Mix.Task.run("format")
  end

  # Format can be :binary or :atom, it changes the way the schemas will be
  # represented in the tests
  defp do_run(suite_name, format, max_tests \\ :infinity) do
    {subnamespace, subdir} =
      case format do
        :binary -> {"BinaryKeys", "binary_keys"}
        :atom -> {"AtomKeys", "atom_keys"}
      end

    test_directory = "test/generated/#{subdir}/#{suite_name}"
    namespace = Module.concat([JSV, Generated, Macro.camelize(String.replace(suite_name, "-", "")), subnamespace])

    CLI.warn("Deleting current test files directory #{test_directory}")
    _ = File.rm_rf!(test_directory)

    enabled =
      case Map.fetch(@enabled, suite_name) do
        {:ok, false} -> Map.new([])
        {:ok, map} when is_map(map) -> map
        :error -> raise ArgumentError, "No suite configuration for #{inspect(suite_name)}"
      end

    enabled = maybe_add_atom_ignored(enabled, format)

    schema_options = [default_meta: default_meta(suite_name)]

    suite_name
    |> stream_cases(enabled)
    |> take_max_tests(max_tests)
    # |> Task.async_stream(&gen_test_mod(&1, test_directory, namespace, jason_keys, schema_options),
    # timeout: :infinity,
    # ordered: false
    # )
    |> Stream.map(&gen_test_mod(&1, test_directory, namespace, format, schema_options))
    |> Enum.count()
    |> then(&IO.puts("Wrote #{&1} files"))
  end

  defp maybe_add_atom_ignored(enabled, :atom) do
    add_atom_ignored(enabled)
  end

  defp maybe_add_atom_ignored(enabled, _) do
    enabled
  end

  defp add_atom_ignored(enabled) do
    Map.new(enabled, fn {jsonpath, opts} ->
      opts =
        if is_list(opts) do
          add_ignored = Keyword.get(opts, :atom_ignore, [])
          Keyword.update(opts, :ignore, add_ignored, &(add_ignored ++ &1))
        else
          opts
        end

      {jsonpath, opts}
    end)
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

  def stream_cases(suite, all_enabled) do
    suite_dir = suite_dir!(suite)

    suite_dir
    |> Path.join("**/**.json")
    |> Path.wildcard()
    |> Enum.sort()
    |> Stream.transform(
      fn -> {_discarded = [], all_enabled} end,
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
        # Cases found in the JSON files that were not configured in
        # `all_enabled`, and so not returned in the stream
        print_unchecked(suite, discarded)

        # Cases configured in `all_enabled` that were not found as JSON files.
        print_unexpected(suite, rest_enabled)
      end
    )
    |> Stream.map(fn item ->
      %{path: path, opts: opts} = item
      Map.put(item, :test_cases, marshall_file(path, opts))
    end)
  end

  defp marshall_file(source_path, opts) do
    # If validate is false, all tests in the file are skipped.
    validate = Keyword.get(opts, :validate, true)
    # TODO remove, This should not be used anymore
    true = validate

    ignore = Keyword.get(opts, :ignore, [])
    elixir = Keyword.get(opts, :elixir, nil)

    source_path
    |> File.read!()
    |> Jason.decode!()
    |> Stream.flat_map(fn tcase ->
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
            skip?: ttest_ignored or tcase_ignored or not validate,
            ignore: ignore
          }
        end)

      all_ignored? = Enum.all?(tests, & &1.skip?)

      if all_ignored? do
        []
      else
        [%{description: tc_descr, schema: schema, tests: tests, elixir_version_check: elixir}]
      end
    end)
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

    """
    Unchecked test cases in #{suite}:
    #{print_list}
    #{(more? && "... (#{total - maxprint} more)") || ""}
    """
    |> IO.warn([])
  end

  defp print_unexpected(_suite, map) when map_size(map) == 0 do
    # no noise
  end

  defp print_unexpected(suite, map) do
    """
    Unexpected test cases in #{suite}:
    #{map |> Map.to_list() |> Enum.map_join("\n", &inspect/1)}
    """
    |> IO.warn([])
  end

  defp gen_test_mod(mod_info, test_directory, namespace, format, schema_options) do
    module_name = module_name(mod_info, namespace)

    case_build_opts = get_in(mod_info, [:opts, :schema_build_opts]) || []
    schema_build_opts = Keyword.merge(schema_options, case_build_opts)

    assigns =
      Map.merge(mod_info, %{module_name: module_name, schema_build_opts: schema_build_opts, keys_format: format})

    module_contents = module_template(assigns)
    module_path = module_path(test_directory, namespace, module_name)

    File.mkdir_p!(Path.dirname(module_path))
    File.write!(module_path, module_contents, [:sync])
    module_path
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
    properties
    required
  ) |> Enum.with_index() |> Map.new()

  defp render_ordered_schema(schema, key_format) when is_map(schema) do
    schema =
      case key_format do
        :binary -> schema
        :atom -> schema |> Jason.encode!() |> Jason.decode!(keys: :atoms)
      end

    ordered_map = JSV.OrderedMap.from_map(schema)
    inspect(ordered_map, pretty: true)
  end

  defp render_ordered_schema(schema, _) when is_boolean(schema) do
    inspect(schema)
  end
end

defmodule JSV.OrderedMap do
  @key_order ["$schema", "$id", "comment", "$defs", "definitions", "type", "properties", "required"]
             |> Enum.with_index()
             |> Map.new()

  defstruct ordlist: []

  def from_map(map) do
    ordlist =
      map
      |> Map.to_list()
      |> Enum.sort_by(fn {k, _} -> order_of(k) end)
      |> Enum.map(fn {k, v} -> {k, cast_sub(v)} end)

    %__MODULE__{ordlist: ordlist}
  end

  defp cast_sub(map) when is_map(map) do
    from_map(map)
  end

  defp cast_sub(list) when is_list(list) do
    Enum.map(list, &cast_sub(&1))
  end

  defp cast_sub(tuple) when is_tuple(tuple) do
    raise "we should not have tuples in JSON data"
  end

  defp cast_sub(sub) do
    sub
  end

  defp order_of(key) do
    Map.get(@key_order, key, 999_999)
  end
end

defimpl Inspect, for: JSV.OrderedMap do
  import Inspect.Algebra

  def inspect(omap, opts) do
    list = omap.ordlist

    fun =
      if Inspect.List.keyword?(list) do
        &Inspect.List.keyword/2
      else
        sep = color(" => ", :map, opts)
        &to_assoc(&1, &2, sep)
      end

    map_container_doc(omap.ordlist, "", opts, fun)
  end

  defp to_assoc({key, value}, opts, sep) do
    concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
  end

  defp map_container_doc(list, name, opts, fun) do
    open = color("%" <> name <> "{", :map, opts)
    sep = color(",", :map, opts)
    close = color("}", :map, opts)
    container_doc(open, list, close, opts, fun, separator: sep, break: :strict)
  end
end

JSV.GenTestSuite.run(System.argv())
