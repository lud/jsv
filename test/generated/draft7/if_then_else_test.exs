# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.IfThenElseTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/if-then-else.json
  """

  describe "ignore if without then or else:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "if": {
            "const": 0
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid when valid against lone if", c do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid when invalid against lone if", c do
      data = "hello"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ignore then without if:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "then": {
            "const": 0
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid when valid against lone then", c do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid when invalid against lone then", c do
      data = "hello"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ignore else without if:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "else": {
            "const": 0
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid when valid against lone else", c do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid when invalid against lone else", c do
      data = "hello"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "if and then without else:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "if": {
            "exclusiveMaximum": 0
          },
          "then": {
            "minimum": -10
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid through then", c do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid through then", c do
      data = -100
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid when if test fails", c do
      data = 3
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "if and else without then:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "else": {
            "multipleOf": 2
          },
          "if": {
            "exclusiveMaximum": 0
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid when if test passes", c do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid through else", c do
      data = 4
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid through else", c do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "validate against correct branch, then vs else:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "else": {
            "multipleOf": 2
          },
          "if": {
            "exclusiveMaximum": 0
          },
          "then": {
            "minimum": -10
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid through then", c do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid through then", c do
      data = -100
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid through else", c do
      data = 4
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid through else", c do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "non-interference across combined schemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "if": {
                "exclusiveMaximum": 0
              }
            },
            {
              "then": {
                "minimum": -10
              }
            },
            {
              "else": {
                "multipleOf": 2
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid, but would have been invalid through then", c do
      data = -100
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid, but would have been invalid through else", c do
      data = 3
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "if with boolean schema true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "else": {
            "const": "else"
          },
          "if": true,
          "then": {
            "const": "then"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "boolean schema true in if always chooses the then path (valid)", c do
      data = "then"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "boolean schema true in if always chooses the then path (invalid)", c do
      data = "else"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "if with boolean schema false:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "else": {
            "const": "else"
          },
          "if": false,
          "then": {
            "const": "then"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "boolean schema false in if always chooses the else path (invalid)", c do
      data = "then"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "boolean schema false in if always chooses the else path (valid)", c do
      data = "else"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "if appears at the end when serialized (keyword processing sequence):" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "else": {
            "const": "other"
          },
          "if": {
            "maxLength": 4
          },
          "then": {
            "const": "yes"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "yes redirects to then and passes", c do
      data = "yes"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "other redirects to else and passes", c do
      data = "other"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no redirects to then and fails", c do
      data = "no"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid redirects to else and fails", c do
      data = "invalid"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
