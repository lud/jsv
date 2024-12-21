# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.ItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/items.json
  """

  describe "a schema given for items:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": {
            "type": "integer"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid items", c do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "wrong type of items", c do
      data = [1, "x"]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ignores non-arrays", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "JavaScript pseudo-array is valid", c do
      data = %{"0" => "invalid", "length" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items with boolean schema (true):" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any array is valid", c do
      data = [1, "foo", true]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is valid", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items with boolean schema (false):" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any non-empty array is invalid", c do
      data = [1, "foo", true]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is valid", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items and subitems:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "item": {
              "type": "array",
              "items": false,
              "prefixItems": [
                {
                  "$ref": "#/$defs/sub-item"
                },
                {
                  "$ref": "#/$defs/sub-item"
                }
              ]
            },
            "sub-item": {
              "type": "object",
              "required": [
                "foo"
              ]
            }
          },
          "type": "array",
          "items": false,
          "prefixItems": [
            {
              "$ref": "#/$defs/item"
            },
            {
              "$ref": "#/$defs/item"
            },
            {
              "$ref": "#/$defs/item"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid items", c do
      data = [
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "too many items", c do
      data = [
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "too many sub-items", c do
      data = [
        [%{"foo" => nil}, %{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "wrong item", c do
      data = [
        %{"foo" => nil},
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "wrong sub-item", c do
      data = [
        [%{}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "fewer items is valid", c do
      data = [[%{"foo" => nil}], [%{"foo" => nil}]]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nested items:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "array",
          "items": {
            "type": "array",
            "items": {
              "type": "array",
              "items": {
                "type": "array",
                "items": {
                  "type": "number"
                }
              }
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid nested array", c do
      data = [[[[1]], [[2], [3]]], [[[4], [5], [6]]]]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "nested array with invalid type", c do
      data = [[[["1"]], [[2], [3]]], [[[4], [5], [6]]]]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "not deep enough", c do
      data = [[[1], [2], [3]], [[4], [5], [6]]]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "prefixItems with no additional items allowed:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": false,
          "prefixItems": [
            {},
            {},
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "empty array", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "fewer number of items present (1)", c do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "fewer number of items present (2)", c do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "equal number of items present", c do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "additional items are not permitted", c do
      data = [1, 2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items does not look in applicators, valid case:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "allOf": [
            {
              "prefixItems": [
                {
                  "minimum": 3
                }
              ]
            }
          ],
          "items": {
            "minimum": 5
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "prefixItems in allOf does not constrain items, invalid case", c do
      data = [3, 5]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "prefixItems in allOf does not constrain items, valid case", c do
      data = [5, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "prefixItems validation adjusts the starting index for items:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": {
            "type": "integer"
          },
          "prefixItems": [
            {
              "type": "string"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid items", c do
      data = ["x", 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "wrong type of second item", c do
      data = ["x", "y"]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items with heterogeneous array:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": false,
          "prefixItems": [
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "heterogeneous invalid instance", c do
      data = ["foo", "bar", 37]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "valid instance", c do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items with null instance elements:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "items": {
            "type": "null"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null elements", c do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
