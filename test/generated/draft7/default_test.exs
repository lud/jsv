# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DefaultTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/default.json
  """

  describe "invalid type for default:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "foo": {
              "type": "integer",
              "default": []
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid when property is specified", c do
      data = %{"foo" => 13}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "still valid when the invalid default is used", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "invalid string value for default:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "bar": {
              "type": "string",
              "default": "bad",
              "minLength": 4
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid when property is specified", c do
      data = %{"bar" => "good"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "still valid when the invalid default is used", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "the default keyword does not do anything if the property is missing:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "type": "object",
          "properties": {
            "alpha": {
              "type": "number",
              "default": 5,
              "maximum": 3
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "an explicit property value is checked against maximum (passing)", c do
      data = %{"alpha" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an explicit property value is checked against maximum (failing)", c do
      data = %{"alpha" => 5}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "missing properties are not filled in with the default", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
