# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.OneOfTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/oneOf.json
  """

  describe "oneOf:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            {
              "type": "integer"
            },
            {
              "minimum": 2
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "first oneOf valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "second oneOf valid", c do
      data = 2.5
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both oneOf valid", c do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "neither oneOf valid", c do
      data = 1.5
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with base schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "string",
          "oneOf": [
            {
              "minLength": 2
            },
            {
              "maxLength": 4
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "mismatch base schema", c do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "one oneOf valid", c do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both oneOf valid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, all true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            true,
            true,
            true
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, one true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            true,
            false,
            false
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, more than one true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            true,
            true,
            false
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, all false:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            false,
            false,
            false
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf complex types:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
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

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "first oneOf valid (complex)", c do
      data = %{"bar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "second oneOf valid (complex)", c do
      data = %{"foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both oneOf valid (complex)", c do
      data = %{"bar" => 2, "foo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "neither oneOf valid (complex)", c do
      data = %{"bar" => "quux", "foo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with empty schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            {
              "type": "number"
            },
            {}
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "one valid - valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both valid - invalid", c do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with required:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "oneOf": [
            {
              "required": [
                "foo",
                "bar"
              ]
            },
            {
              "required": [
                "foo",
                "baz"
              ]
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "both invalid - invalid", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "first valid - valid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "second valid - valid", c do
      data = %{"baz" => 3, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both valid - invalid", c do
      data = %{"bar" => 2, "baz" => 3, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "oneOf with missing optional property:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            {
              "properties": {
                "bar": true,
                "baz": true
              },
              "required": [
                "bar"
              ]
            },
            {
              "properties": {
                "foo": true
              },
              "required": [
                "foo"
              ]
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "first oneOf valid", c do
      data = %{"bar" => 8}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "second oneOf valid", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both oneOf valid", c do
      data = %{"bar" => 8, "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "neither oneOf valid", c do
      data = %{"baz" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested oneOf, to check validation semantics:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "oneOf": [
            {
              "oneOf": [
                {
                  "type": "null"
                }
              ]
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
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
end
