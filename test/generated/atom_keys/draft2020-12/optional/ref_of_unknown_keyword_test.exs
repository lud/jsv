# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.Optional.RefOfUnknownKeywordTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/refOfUnknownKeyword.json
  """

  describe "reference of a root arbitrary keyword " do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{bar: %JSV.Schema{"$ref": "#/unknown-keyword"}},
        "unknown-keyword": %JSV.Schema{type: "integer"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = %{"bar" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = %{"bar" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "reference of an arbitrary keyword of a sub-schema" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          bar: %JSV.Schema{"$ref": "#/properties/foo/unknown-keyword"},
          foo: %{"unknown-keyword": %JSV.Schema{type: "integer"}}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = %{"bar" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = %{"bar" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "reference internals of known non-applicator" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "/base",
        "$ref": "#/examples/0",
        examples: [%JSV.Schema{type: "string"}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = "a string"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = 42
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
