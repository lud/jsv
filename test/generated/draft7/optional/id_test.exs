# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.Optional.IdTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/optional/id.json
  """

  describe "id inside an enum is not a real identifier:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "id_in_enum": {
              "enum": [
                {
                  "$id": "https://localhost:1234/id/my_identifier.json",
                  "type": "null"
                }
              ]
            },
            "real_id_in_schema": {
              "$id": "https://localhost:1234/id/my_identifier.json",
              "type": "string"
            },
            "zzz_id_in_const": {
              "const": {
                "$id": "https://localhost:1234/id/my_identifier.json",
                "type": "null"
              }
            }
          },
          "anyOf": [
            {
              "$ref": "#/definitions/id_in_enum"
            },
            {
              "$ref": "https://localhost:1234/id/my_identifier.json"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "exact match to enum, and type matches", c do
      data = %{"$id" => "https://localhost:1234/id/my_identifier.json", "type" => "null"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "match $ref to id", c do
      data = "a string to match #/definitions/id_in_enum"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no match on enum or $ref to id", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "non-schema object containing a plain-name $id property:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "const_not_anchor": {
              "const": {
                "$id": "#not_a_real_anchor"
              }
            }
          },
          "else": {
            "$ref": "#/definitions/const_not_anchor"
          },
          "if": {
            "const": "skip not_a_real_anchor"
          },
          "then": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "skip traversing definition for a valid result", c do
      data = "skip not_a_real_anchor"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "const at const_not_anchor does not match", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "non-schema object containing an $id property:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "const_not_id": {
              "const": {
                "$id": "not_a_real_id"
              }
            }
          },
          "else": {
            "$ref": "#/definitions/const_not_id"
          },
          "if": {
            "const": "skip not_a_real_id"
          },
          "then": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "skip traversing definition for a valid result", c do
      data = "skip not_a_real_id"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "const at const_not_id does not match", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
