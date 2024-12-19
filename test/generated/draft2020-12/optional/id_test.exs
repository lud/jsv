# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.Optional.IdTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/id.json
  """

  describe "$id inside an enum is not a real identifier:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "id_in_enum": {
              "enum": [
                {
                  "$id": "https://localhost:1234/draft2020-12/id/my_identifier.json",
                  "type": "null"
                }
              ]
            },
            "real_id_in_schema": {
              "$id": "https://localhost:1234/draft2020-12/id/my_identifier.json",
              "type": "string"
            },
            "zzz_id_in_const": {
              "const": {
                "$id": "https://localhost:1234/draft2020-12/id/my_identifier.json",
                "type": "null"
              }
            }
          },
          "anyOf": [
            {
              "$ref": "#/$defs/id_in_enum"
            },
            {
              "$ref": "https://localhost:1234/draft2020-12/id/my_identifier.json"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "exact match to enum, and type matches", c do
      data = %{
        "$id" => "https://localhost:1234/draft2020-12/id/my_identifier.json",
        "type" => "null"
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "match $ref to $id", c do
      data = "a string to match #/$defs/id_in_enum"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no match on enum or $ref to $id", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
