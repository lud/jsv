# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.ContainsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/contains.json
  """

  describe "contains keyword validation" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: %JSV.Schema{minimum: 5}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "array with item matching schema (5) is valid", x do
      data = [3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "array with item matching schema (6) is valid", x do
      data = [3, 4, 6]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "array with two items matching schema (5, 6) is valid", x do
      data = [3, 4, 5, 6]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "array without items matching schema is invalid", x do
      data = [2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is invalid", x do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not array is valid", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "contains keyword with const keyword" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: %{const: 5}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "array with item 5 is valid", x do
      data = [3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "array with two items 5 is valid", x do
      data = [3, 4, 5, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "array without item 5 is invalid", x do
      data = [1, 2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "contains keyword with boolean schema true" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any non-empty array is valid", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is invalid", x do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "contains keyword with boolean schema false" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any non-empty array is invalid", x do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is invalid", x do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-arrays are valid", x do
      data = "contains does not apply to strings"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items + contains" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: %JSV.Schema{multipleOf: 3},
        items: %JSV.Schema{multipleOf: 2}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "matches items, does not match contains", x do
      data = [2, 4, 8]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "does not match items, matches contains", x do
      data = [3, 6, 9]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "matches both items and contains", x do
      data = [6, 12]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "matches neither items nor contains", x do
      data = [1, 5]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "contains with false if subschema" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: %JSV.Schema{else: true, if: false}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any non-empty array is valid", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is invalid", x do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "contains with null instance elements" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        contains: %JSV.Schema{type: "null"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null items", x do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
