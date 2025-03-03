# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.Optional.DynamicRefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/dynamicRef.json
  """

  describe "$dynamicRef skips over intermediate resources - pointer reference across resource boundary" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://test.json-schema.org/dynamic-ref-skips-intermediate-resource/optional/main",
        "$defs": %{
          bar: %JSV.Schema{
            "$id": "bar",
            "$defs": %{
              content: %JSV.Schema{"$dynamicAnchor": "content", type: "string"},
              item: %JSV.Schema{
                "$id": "item",
                "$defs": %{
                  defaultContent: %JSV.Schema{
                    "$dynamicAnchor": "content",
                    type: "integer"
                  }
                },
                type: "object",
                properties: %{content: %JSV.Schema{"$dynamicRef": "#content"}}
              }
            },
            type: "array",
            items: %JSV.Schema{"$ref": "item"}
          }
        },
        type: "object",
        properties: %{"bar-item": %JSV.Schema{"$ref": "bar#/$defs/item"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "integer property passes", x do
      data = %{"bar-item" => %{"content" => 42}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "string property fails", x do
      data = %{"bar-item" => %{"content" => "value"}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
