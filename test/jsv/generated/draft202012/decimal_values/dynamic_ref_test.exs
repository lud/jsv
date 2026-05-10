# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.DecimalValues.DynamicRefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/dynamicRef.json
  """

  describe "multiple dynamic paths to the $dynamicRef keyword" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$id" => "https://test.json-schema.org/dynamic-ref-with-multiple-paths/main",
        "$defs" => %{
          "genericList" => %{
            "$id" => "genericList",
            "$defs" => %{
              "defaultItemType" => %{
                "$dynamicAnchor" => "itemType",
                "$comment" => "Only needed to satisfy bookending requirement"
              }
            },
            "properties" => %{"list" => %{"items" => %{"$dynamicRef" => "#itemType"}}}
          },
          "numberList" => %{
            "$id" => "numberList",
            "$defs" => %{
              "itemType" => %{"$dynamicAnchor" => "itemType", "type" => "number"}
            },
            "$ref" => "genericList"
          },
          "stringList" => %{
            "$id" => "stringList",
            "$defs" => %{
              "itemType" => %{"$dynamicAnchor" => "itemType", "type" => "string"}
            },
            "$ref" => "genericList"
          }
        },
        "else" => %{"$ref" => "stringList"},
        "if" => %{
          "properties" => %{"kindOfList" => %{"const" => "numbers"}},
          "required" => ["kindOfList"]
        },
        "then" => %{"$ref" => "numberList"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number list with number values", x do
      data = %{
        "kindOfList" => "numbers",
        "list" => [Decimal.new("1.1", JsonSchemaSuite.decimal_opts())]
      }

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "string list with number values", x do
      data = %{
        "kindOfList" => "strings",
        "list" => [Decimal.new("1.1", JsonSchemaSuite.decimal_opts())]
      }

      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
