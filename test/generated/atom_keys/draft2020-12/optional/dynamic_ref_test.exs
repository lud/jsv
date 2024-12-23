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
        type: "object",
        "$defs": %{
          bar: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$ref": "item"},
            "$defs": %{
              item: %JSV.Schema{
                type: "object",
                "$defs": %{
                  defaultContent: %JSV.Schema{
                    type: "integer",
                    "$dynamicAnchor": "content"
                  }
                },
                "$id": "item",
                properties: %{content: %JSV.Schema{"$dynamicRef": "#content"}}
              },
              content: %JSV.Schema{type: "string", "$dynamicAnchor": "content"}
            },
            "$id": "bar"
          }
        },
        "$id": "https://test.json-schema.org/dynamic-ref-skips-intermediate-resource/optional/main",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
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
