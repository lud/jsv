# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.PropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/properties.json
  """

  describe "object properties validation:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "bar": {
              "type": "string"
            },
            "foo": {
              "type": "integer"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "both properties present and valid is valid", c do
      data = %{"bar" => "baz", "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "one property invalid is invalid", c do
      data = %{"bar" => %{}, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both properties invalid is invalid", c do
      data = %{"bar" => %{}, "foo" => []}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "doesn't invalidate other properties", c do
      data = %{"quux" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "properties, patternProperties, additionalProperties interaction:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": {
            "type": "integer"
          },
          "patternProperties": {
            "f.o": {
              "minItems": 2
            }
          },
          "properties": {
            "bar": {
              "type": "array"
            },
            "foo": {
              "type": "array",
              "maxItems": 3
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "property validates property", c do
      data = %{"foo" => [1, 2]}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "property invalidates property", c do
      data = %{"foo" => [1, 2, 3, 4]}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "patternProperty invalidates property", c do
      data = %{"foo" => []}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "patternProperty validates nonproperty", c do
      data = %{"fxo" => [1, 2]}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "patternProperty invalidates nonproperty", c do
      data = %{"fxo" => []}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "additionalProperty ignores property", c do
      data = %{"bar" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "additionalProperty validates others", c do
      data = %{"quux" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "additionalProperty invalidates others", c do
      data = %{"quux" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "properties with boolean schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "bar": false,
            "foo": true
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no property present is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "only 'true' property present is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "only 'false' property present is invalid", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both properties present is invalid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "properties with escaped characters:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "foo\tbar": {
              "type": "number"
            },
            "foo\nbar": {
              "type": "number"
            },
            "foo\fbar": {
              "type": "number"
            },
            "foo\rbar": {
              "type": "number"
            },
            "foo\"bar": {
              "type": "number"
            },
            "foo\\bar": {
              "type": "number"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with all numbers is valid", c do
      data = %{
        "foo\tbar" => 1,
        "foo\nbar" => 1,
        "foo\fbar" => 1,
        "foo\rbar" => 1,
        "foo\"bar" => 1,
        "foo\\bar" => 1
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object with strings is invalid", c do
      data = %{
        "foo\tbar" => "1",
        "foo\nbar" => "1",
        "foo\fbar" => "1",
        "foo\rbar" => "1",
        "foo\"bar" => "1",
        "foo\\bar" => "1"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "properties with null valued instance properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "foo": {
              "type": "null"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null values", c do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "properties whose names are Javascript object property names:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "__proto__": {
              "type": "number"
            },
            "constructor": {
              "type": "number"
            },
            "toString": {
              "properties": {
                "length": {
                  "type": "string"
                }
              }
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "ignores arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "none of the properties mentioned", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "__proto__ not valid", c do
      data = %{"__proto__" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "toString not valid", c do
      data = %{"toString" => %{"length" => 37}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "constructor not valid", c do
      data = %{"constructor" => %{"length" => 37}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all present and valid", c do
      data = %{"__proto__" => 12, "constructor" => 37, "toString" => %{"length" => "foo"}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
