# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.Optional.FormatAssertionTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format-assertion.json
  """

  describe "schema that uses custom metaschema with format-assertion: false" do
    setup do
      json_schema = %{
        "$schema" => "http://localhost:1234/draft2020-12/format-assertion-false.json",
        "$id" => "https://schema/using/format-assertion/false",
        "format" => "ipv4"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "format-assertion: false: valid string", x do
      data = "127.0.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "format-assertion: false: invalid string", x do
      data = "not-an-ipv4"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "schema that uses custom metaschema with format-assertion: true" do
    setup do
      json_schema = %{
        "$schema" => "http://localhost:1234/draft2020-12/format-assertion-true.json",
        "$id" => "https://schema/using/format-assertion/true",
        "format" => "ipv4"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "format-assertion: true: valid string", x do
      data = "127.0.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "format-assertion: true: invalid string", x do
      data = "not-an-ipv4"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
