# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AdditionalItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/additionalItems.json
  """

  describe "additionalItems as schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": {
            "type": "integer"
          },
          "items": [
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "additional items match schema", c do
      data = [nil, 2, 3, 4]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "additional items do not match schema", c do
      data = [nil, 2, 3, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "when items is schema, additionalItems does nothing:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": {
            "type": "string"
          },
          "items": {
            "type": "integer"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid with a array of type integers", c do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "invalid with a array of mixed types", c do
      data = [1, "2", "3"]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "when items is schema, boolean additionalItems does nothing:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": false,
          "items": {}
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all items match schema", c do
      data = [1, 2, 3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "array of items with no additionalItems permitted:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": false,
          "items": [
            {},
            {},
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

  describe "additionalItems as false without items:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "items defaults to empty schema so everything is valid", c do
      data = [1, 2, 3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ignores non-arrays", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems are allowed by default:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": [
            {
              "type": "integer"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "only the first item is validated", c do
      data = [1, "foo", false]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems does not look in applicators, valid case:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": {
            "type": "boolean"
          },
          "allOf": [
            {
              "items": [
                {
                  "type": "integer"
                }
              ]
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "items defined in allOf are not examined", c do
      data = [1, nil]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems does not look in applicators, invalid case:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": {
            "type": "boolean"
          },
          "allOf": [
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
          ],
          "items": [
            {
              "type": "integer"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "items defined in allOf are not examined", c do
      data = [1, "hello"]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items validation adjusts the starting index for additionalItems:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": {
            "type": "integer"
          },
          "items": [
            {
              "type": "string"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

  describe "additionalItems with heterogeneous array:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": false,
          "items": [
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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

  describe "additionalItems with null instance elements:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalItems": {
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
end
