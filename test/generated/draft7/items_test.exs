# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.ItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/items.json
  """

  describe "a schema given for items:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": {
            "type": "integer"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

  describe "an array of schemas for items:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": [
            {
              "type": "integer"
            },
            {
              "type": "string"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "correct types", c do
      data = [1, "foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "wrong types", c do
      data = ["foo", 1]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "incomplete array of items", c do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "array with additional items", c do
      data = [1, "foo", true]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "empty array", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "JavaScript pseudo-array is valid", c do
      data = %{"0" => "invalid", "1" => "valid", "length" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items with boolean schema (true):" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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
          "items": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

  describe "items with boolean schemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": [
            true,
            false
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "array with one item is valid", c do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "array with two items is invalid", c do
      data = [1, "foo"]
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
          "definitions": {
            "item": {
              "type": "array",
              "additionalItems": false,
              "items": [
                {
                  "$ref": "#/definitions/sub-item"
                },
                {
                  "$ref": "#/definitions/sub-item"
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
          "additionalItems": false,
          "items": [
            {
              "$ref": "#/definitions/item"
            },
            {
              "$ref": "#/definitions/item"
            },
            {
              "$ref": "#/definitions/item"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

  describe "single-form items with null instance elements:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": {
            "type": "null"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null elements", c do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "array-form items with null instance elements:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": [
            {
              "type": "null"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null elements", c do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
