# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AdditionalPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/additionalProperties.json
  """

  describe "additionalProperties being false does not allow other properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": false,
          "patternProperties": {
            "^v": {}
          },
          "properties": {
            "bar": {},
            "foo": {}
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no additional properties is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional property is invalid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => "boom"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores strings", c do
      data = "foobarbaz"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "patternProperties are not additional properties", c do
      data = %{"foo" => 1, "vroom" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "non-ASCII pattern with additionalProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": false,
          "patternProperties": {
            "^á": {}
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "matching the pattern is valid", c do
      data = %{"ármányos" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "not matching the pattern is invalid", c do
      data = %{"élmény" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties with schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": {
            "type": "boolean"
          },
          "properties": {
            "bar": {},
            "foo": {}
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no additional properties is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional valid property is valid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional invalid property is invalid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties can exist by itself:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": {
            "type": "boolean"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "an additional valid property is valid", c do
      data = %{"foo" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional invalid property is invalid", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties are allowed by default:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "bar": {},
            "foo": {}
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "additional properties are allowed", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties does not look in applicators:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": {
            "type": "boolean"
          },
          "allOf": [
            {
              "properties": {
                "foo": {}
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "properties defined in allOf are not examined", c do
      data = %{"bar" => true, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties with null valued instance properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": {
            "type": "null"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null values", c do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
