# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.Optional.AnchorTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/anchor.json
  """

  describe "$anchor inside an enum is not a real identifier:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "anchor_in_enum": {
              "enum": [
                {
                  "type": "null",
                  "$anchor": "my_anchor"
                }
              ]
            },
            "real_identifier_in_schema": {
              "type": "string",
              "$anchor": "my_anchor"
            },
            "zzz_anchor_in_const": {
              "const": {
                "type": "null",
                "$anchor": "my_anchor"
              }
            }
          },
          "anyOf": [
            {
              "$ref": "#/$defs/anchor_in_enum"
            },
            {
              "$ref": "#my_anchor"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "exact match to enum, and type matches", c do
      data = %{"$anchor" => "my_anchor", "type" => "null"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "in implementations that strip $anchor, this may match either $def", c do
      data = %{"type" => "null"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "match $ref to $anchor", c do
      data = "a string to match #/$defs/anchor_in_enum"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no match on enum or $ref to $anchor", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
