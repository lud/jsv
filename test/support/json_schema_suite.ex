defmodule JSV.Test.JsonSchemaSuite do
  alias JSV.Validator
  use ExUnit.CaseTemplate
  @root_suites_dir Path.join([File.cwd!(), "deps", "json_schema_test_suite", "tests"])
  require Logger
  import ExUnit.Assertions

  def stream_cases(suite, all_enabled) do
    suite_dir = suite_dir!(suite)

    suite_dir
    |> Path.join("**/**.json")
    |> Path.wildcard()
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
        print_unchecked(suite, discarded)
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

    ignored = Keyword.get(opts, :ignore, [])
    elixir = Keyword.get(opts, :elixir, nil)

    source_path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn tcase ->
      %{"description" => tc_descr, "schema" => schema, "tests" => tests} = tcase
      tcase_ignored = tc_descr in ignored

      tests =
        Enum.map(tests, fn ttest ->
          %{"description" => tt_descr, "data" => data, "valid" => valid} = ttest
          ttest_ignored = tt_descr in ignored

          %{description: tt_descr, data: data, valid?: valid, skip?: ttest_ignored or tcase_ignored or not validate}
        end)

      %{description: tc_descr, schema: schema, tests: tests, elixir_version_check: elixir}
    end)
  end

  def suite_dir!(suite) do
    path = Path.join(@root_suites_dir, suite)

    case File.dir?(path) do
      true -> path
      false -> raise ArgumentError, "unknown suite #{suite}, could not find directory #{path}"
    end
  end

  def run_test(json_schema, schema, data, expected_valid) do
    {valid?, %Validator{} = validator} =
      case JSV.validation_entrypoint(schema, data) do
        {:ok, casted, vdr} ->
          # This may fail if we have casting during the validation.
          assert data == casted
          {true, vdr}

        {:error, validator} ->
          {false, validator}
      end

    # assert the expected result

    case {expected_valid, valid?} do
      {true, true} ->
        :ok

      {false, false} ->
        _ = test_error_format(validator)
        :ok

      _ ->
        flunk("""
        #{if expected_valid do
          "Expected valid, got errors"
        else
          "Expected errors, got valid"
        end}

        JSON SCHEMA
        #{inspect(json_schema, pretty: true)}

        DATA
        #{inspect(data, pretty: true)}

        SCHEMA
        #{inspect(schema, pretty: true)}

        ERRORS
        #{inspect(validator.errors, pretty: true)}
        """)
    end
  end

  defp test_error_format(validator) do
    formatted = Validator.format_errors(validator)
    assert is_list(formatted)

    Enum.each(formatted, fn err ->
      _ = assert {:ok, message} = Map.fetch(err, :message)
      _ = assert is_binary(message)
    end)

    assert {:ok, _} = Jason.encode(formatted)
  end

  def build_schema(json_schema, build_opts) do
    case JSV.build(json_schema, [resolver: {JSV.Test.TestResolver, [fake_opts: true]}] ++ build_opts) do
      {:ok, schema} -> schema
      {:error, reason} -> flunk(denorm_failure(json_schema, reason, []))
    end
  rescue
    e in FunctionClauseError ->
      IO.puts(denorm_failure(json_schema, e, __STACKTRACE__))
      reraise e, __STACKTRACE__
  end

  defp denorm_failure(json_schema, reason, stacktrace) do
    """
    Failed to denormalize schema.

    SCHEMA
    #{inspect(json_schema, pretty: true)}

    ERROR
    #{if is_exception(reason) do
      Exception.format(:error, reason, stacktrace)
    else
      inspect(reason, pretty: true)
    end}
    """
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

  def version_check(elixir_version_req) do
    Version.match?(System.version(), elixir_version_req)
  end
end
