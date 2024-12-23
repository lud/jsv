# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.Optional.IdTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/id.json
  """

  describe "$id inside an enum is not a real identifier" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          id_in_enum: %JSV.Schema{
            enum: [
              %JSV.Schema{
                type: "null",
                "$id": "https://localhost:1234/draft2020-12/id/my_identifier.json"
              }
            ]
          },
          real_id_in_schema: %JSV.Schema{
            type: "string",
            "$id": "https://localhost:1234/draft2020-12/id/my_identifier.json"
          },
          zzz_id_in_const: %{
            const: %JSV.Schema{
              type: "null",
              "$id": "https://localhost:1234/draft2020-12/id/my_identifier.json"
            }
          }
        },
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        anyOf: [
          %JSV.Schema{"$ref": "#/$defs/id_in_enum"},
          %JSV.Schema{
            "$ref": "https://localhost:1234/draft2020-12/id/my_identifier.json"
          }
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "exact match to enum, and type matches", x do
      data = %{
        "$id" => "https://localhost:1234/draft2020-12/id/my_identifier.json",
        "type" => "null"
      }

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "match $ref to $id", x do
      data = "a string to match #/$defs/id_in_enum"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "no match on enum or $ref to $id", x do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
