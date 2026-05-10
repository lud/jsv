# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DecimalValues.RefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/ref.json
  """

  describe "Recursive references between schemas" do
    setup do
      json_schema = %{
        "$id" => "http://localhost:1234/tree",
        "description" => "tree of nodes",
        "definitions" => %{
          "node" => %{
            "$id" => "http://localhost:1234/node",
            "description" => "node",
            "type" => "object",
            "properties" => %{
              "subtree" => %{"$ref" => "tree"},
              "value" => %{"type" => "number"}
            },
            "required" => ["value"]
          }
        },
        "type" => "object",
        "properties" => %{
          "meta" => %{"type" => "string"},
          "nodes" => %{"type" => "array", "items" => %{"$ref" => "node"}}
        },
        "required" => ["meta", "nodes"]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid tree", x do
      data = %{
        "meta" => "root",
        "nodes" => [
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [
                %{"value" => Decimal.new("1.1", JsonSchemaSuite.decimal_opts())},
                %{"value" => Decimal.new("1.2", JsonSchemaSuite.decimal_opts())}
              ]
            },
            "value" => 1
          },
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [
                %{"value" => Decimal.new("2.1", JsonSchemaSuite.decimal_opts())},
                %{"value" => Decimal.new("2.2", JsonSchemaSuite.decimal_opts())}
              ]
            },
            "value" => 2
          }
        ]
      }

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid tree", x do
      data = %{
        "meta" => "root",
        "nodes" => [
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [
                %{"value" => "string is invalid"},
                %{"value" => Decimal.new("1.2", JsonSchemaSuite.decimal_opts())}
              ]
            },
            "value" => 1
          },
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [
                %{"value" => Decimal.new("2.1", JsonSchemaSuite.decimal_opts())},
                %{"value" => Decimal.new("2.2", JsonSchemaSuite.decimal_opts())}
              ]
            },
            "value" => 2
          }
        ]
      }

      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
