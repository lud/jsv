defmodule JSV.Test.JsonSchemaSuite do
  alias JSV.Validator
  import ExUnit.Assertions
  require Logger
  use ExUnit.CaseTemplate

  def run_test(json_schema, schema, data, expected_valid, opts \\ []) do
    {valid?, %Validator{} = validator} =
      case JSV.validation_entrypoint(schema, data) do
        {:ok, casted, vctx} ->
          # This may fail if we have casting during the validation.
          assert data == casted
          {true, vctx}

        {:error, validator} ->
          _ = test_error_format(validator, opts)
          {false, validator}
      end

    # assert the expected result

    case {expected_valid, valid?} do
      {true, true} ->
        :ok

      {false, false} ->
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

  defp test_error_format(validator, opts) do
    formatted = JSV.format_errors(validator)
    assert is_list(formatted)

    Enum.each(formatted, fn err ->
      _ = assert false == err.valid
      _ = assert is_list(err.errors)
      _ = assert is_binary(err.evaluationPath)
      _ = assert is_binary(err.schemaLocation)
      _ = assert is_binary(err.instanceLocation)
    end)

    # Json encodable
    _ = assert {:ok, json_errors} = Jason.encode(formatted, pretty: true)

    if opts[:print_errors] do
      IO.puts(["\n", json_errors])
    end
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

  def version_check(elixir_version_req) do
    Version.match?(System.version(), elixir_version_req)
  end
end
