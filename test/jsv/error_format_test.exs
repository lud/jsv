defmodule JSV.ErrorFormatTest do
  alias JSV
  alias JSV.Validator
  use ExUnit.Case, async: true

  defp build_schema!(json_schema, opts \\ []) do
    {:ok, schema} = JSV.build(json_schema, [resolver: JSV.Test.TestResolver] ++ opts)
    schema
  end

  test "sample example from json-schema.org blog" do
    schema =
      build_schema!(
        Jason.decode!(~S"""
        {
          "$id": "https://example.com/polygon",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "point": {
              "$id": "pointSchema",
              "type": "object",
              "properties": {
                "x": { "type": "number" },
                "y": { "type": "number" }
              },
              "additionalProperties": false,
              "required": [ "x", "y" ]
            }
          },
          "type": "array",
          "items": { "$ref": "#/$defs/point" },
          "prefixItems": [
          {"type": "number"}
          ],
          "minItems": 3
        }
        """)
      )

    invalid_data = [
      %{
        "x" => 2.5,
        "y" => 1.3
      },
      %{
        "x" => 1,
        "z" => 6.7
      }
    ]

    assert {:error, {:schema_validation, errors}} = JSV.validate(invalid_data, schema)
    formatted_errors = JSV.format_errors(errors)
    # flunk("ok so far")
  end
end
