# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DependenciesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/dependencies.json
  """

  describe "dependencies:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "bar": [
              "foo"
            ]
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "neither", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "nondependant", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with dependency", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "missing dependency", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = ["bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores strings", c do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "dependencies with empty array:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "bar": []
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "empty object", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object with one property", c do
      data = %{"bar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "non-object is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "multiple dependencies:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "quux": [
              "foo",
              "bar"
            ]
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "neither", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "nondependants", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with dependencies", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "missing dependency", c do
      data = %{"foo" => 1, "quux" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "missing other dependency", c do
      data = %{"bar" => 1, "quux" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "missing both dependencies", c do
      data = %{"quux" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "multiple dependencies subschema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "bar": {
              "properties": {
                "bar": {
                  "type": "integer"
                },
                "foo": {
                  "type": "integer"
                }
              }
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no dependency", c do
      data = %{"foo" => "quux"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "wrong type", c do
      data = %{"bar" => 2, "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "wrong type other", c do
      data = %{"bar" => "quux", "foo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "wrong type both", c do
      data = %{"bar" => "quux", "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "dependencies with boolean subschemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "bar": false,
            "foo": true
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with property having schema true is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object with property having schema false is invalid", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object with both properties is invalid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "empty object is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "dependencies with escaped characters:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "foo\tbar": {
              "minProperties": 4
            },
            "foo\nbar": [
              "foo\rbar"
            ],
            "foo\"bar": [
              "foo'bar"
            ],
            "foo'bar": {
              "required": [
                "foo\"bar"
              ]
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid object 1", c do
      data = %{"foo\nbar" => 1, "foo\rbar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid object 2", c do
      data = %{"a" => 2, "b" => 3, "c" => 4, "foo\tbar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid object 3", c do
      data = %{"foo\"bar" => 2, "foo'bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid object 1", c do
      data = %{"foo" => 2, "foo\nbar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid object 2", c do
      data = %{"a" => 2, "foo\tbar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid object 3", c do
      data = %{"foo'bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid object 4", c do
      data = %{"foo\"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "dependent subschema incompatible with root:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "dependencies": {
            "foo": {
              "additionalProperties": false,
              "properties": {
                "bar": {}
              }
            }
          },
          "properties": {
            "foo": {}
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "matches root", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "matches dependency", c do
      data = %{"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "matches both", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no dependency", c do
      data = %{"baz" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
