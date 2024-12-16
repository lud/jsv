# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AllOfTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/allOf.json
  """

  describe "allOf:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "properties": {
                "bar": {
                  "type": "integer"
                }
              },
              "required": [
                "bar"
              ]
            },
            {
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "required": [
                "foo"
              ]
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allOf", c do
      data = %{"bar" => 2, "foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch second", c do
      data = %{"foo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch first", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "wrong type", c do
      data = %{"bar" => "quux", "foo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with base schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "required": [
                "foo"
              ]
            },
            {
              "properties": {
                "baz": {
                  "type": "null"
                }
              },
              "required": [
                "baz"
              ]
            }
          ],
          "properties": {
            "bar": {
              "type": "integer"
            }
          },
          "required": [
            "bar"
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid", c do
      data = %{"bar" => 2, "baz" => nil, "foo" => "quux"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch base schema", c do
      data = %{"baz" => nil, "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch first allOf", c do
      data = %{"bar" => 2, "baz" => nil}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch second allOf", c do
      data = %{"bar" => 2, "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch both", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf simple types:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "maximum": 30
            },
            {
              "minimum": 20
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid", c do
      data = 25
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch one", c do
      data = 35
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with boolean schemas, all true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            true,
            true
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with boolean schemas, some false:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            true,
            false
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with boolean schemas, all false:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            false,
            false
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with one empty schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any data is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with two empty schemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {},
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any data is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with the first empty schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {},
            {
              "type": "number"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf with the last empty schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "type": "number"
            },
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested allOf, to check validation semantics:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "allOf": [
                {
                  "type": "null"
                }
              ]
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "null is valid", c do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "anything non-null is invalid", c do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "allOf combined with anyOf, oneOf:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "multipleOf": 2
            }
          ],
          "anyOf": [
            {
              "multipleOf": 3
            }
          ],
          "oneOf": [
            {
              "multipleOf": 5
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allOf: false, anyOf: false, oneOf: false", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: false, anyOf: false, oneOf: true", c do
      data = 5
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: false, anyOf: true, oneOf: false", c do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: false, anyOf: true, oneOf: true", c do
      data = 15
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: true, anyOf: false, oneOf: false", c do
      data = 2
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: true, anyOf: false, oneOf: true", c do
      data = 10
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: true, anyOf: true, oneOf: false", c do
      data = 6
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "allOf: true, anyOf: true, oneOf: true", c do
      data = 30
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
