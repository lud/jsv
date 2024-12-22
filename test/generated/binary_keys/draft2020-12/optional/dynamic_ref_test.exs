# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.Optional.DynamicRefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/dynamicRef.json
  """

  describe "$dynamicRef skips over intermediate resources - pointer reference across resource boundary" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$id" => "https://test.json-schema.org/dynamic-ref-skips-intermediate-resource/optional/main",
        "$defs" => %{
          "bar" => %{
            "$id" => "bar",
            "$defs" => %{
              "content" => %{"type" => "string", "$dynamicAnchor" => "content"},
              "item" => %{
                "$id" => "item",
                "$defs" => %{
                  "defaultContent" => %{
                    "type" => "integer",
                    "$dynamicAnchor" => "content"
                  }
                },
                "type" => "object",
                "properties" => %{"content" => %{"$dynamicRef" => "#content"}}
              }
            },
            "type" => "array",
            "items" => %{"$ref" => "item"}
          }
        },
        "type" => "object",
        "properties" => %{"bar-item" => %{"$ref" => "bar#/$defs/item"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "integer property passes", c do
      data = %{"bar-item" => %{"content" => 42}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "string property fails", c do
      data = %{"bar-item" => %{"content" => "value"}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
