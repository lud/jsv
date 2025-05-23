# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.UnevaluatedItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/unevaluatedItems.json
  """

  describe "unevaluatedItems true" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedItems" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems false" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems as schema" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedItems" => %{"type" => "string"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with valid unevaluated items", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with invalid unevaluated items", x do
      data = ~c"*"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with uniform items" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"type" => "string"},
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "unevaluatedItems doesn't apply", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with tuple" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "string"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with items and prefixItems" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => true,
        "prefixItems" => [%{"type" => "string"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "unevaluatedItems doesn't apply", x do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with items" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"type" => "number"},
        "unevaluatedItems" => %{"type" => "string"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid under items", x do
      data = [5, 6, 7, 8]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid under items", x do
      data = ["foo", "bar", "baz"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with nested tuple" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"prefixItems" => [true, %{"type" => "number"}]}],
        "prefixItems" => [%{"type" => "string"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo", 42, true]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with nested items" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [%{"items" => %{"type" => "string"}}, true],
        "unevaluatedItems" => %{"type" => "boolean"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with only (valid) additional items", x do
      data = [true, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with no additional items", x do
      data = ["yes", "no"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with invalid additional item", x do
      data = ["yes", false]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with nested prefixItems and items" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"items" => true, "prefixItems" => [%{"type" => "string"}]}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional items", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with additional items", x do
      data = ["foo", 42, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with nested unevaluatedItems" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"prefixItems" => [%{"type" => "string"}]},
          %{"unevaluatedItems" => true}
        ],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional items", x do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with additional items", x do
      data = ["foo", 42, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with anyOf" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [
          %{"prefixItems" => [true, %{"const" => "bar"}]},
          %{"prefixItems" => [true, true, %{"const" => "baz"}]}
        ],
        "prefixItems" => [%{"const" => "foo"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when one schema matches and has no unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when one schema matches and has unevaluated items", x do
      data = ["foo", "bar", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when two schemas match and has no unevaluated items", x do
      data = ["foo", "bar", "baz"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when two schemas match and has unevaluated items", x do
      data = ["foo", "bar", "baz", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with oneOf" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [
          %{"prefixItems" => [true, %{"const" => "bar"}]},
          %{"prefixItems" => [true, %{"const" => "baz"}]}
        ],
        "prefixItems" => [%{"const" => "foo"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo", "bar", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with not" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "not" => %{"not" => %{"prefixItems" => [true, %{"const" => "bar"}]}},
        "prefixItems" => [%{"const" => "foo"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with if/then/else" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"prefixItems" => [true, true, true, %{"const" => "else"}]},
        "if" => %{"prefixItems" => [true, %{"const" => "bar"}]},
        "prefixItems" => [%{"const" => "foo"}],
        "then" => %{"prefixItems" => [true, true, %{"const" => "then"}]},
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if matches and it has no unevaluated items", x do
      data = ["foo", "bar", "then"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if matches and it has unevaluated items", x do
      data = ["foo", "bar", "then", "else"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if doesn't match and it has no unevaluated items", x do
      data = ["foo", 42, 42, "else"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if doesn't match and it has unevaluated items", x do
      data = ["foo", 42, 42, "else", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with boolean schemas" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [true],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with $ref" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$defs" => %{"bar" => %{"prefixItems" => [true, %{"type" => "string"}]}},
        "$ref" => "#/$defs/bar",
        "prefixItems" => [%{"type" => "string"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo", "bar", "baz"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems before $ref" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$defs" => %{"bar" => %{"prefixItems" => [true, %{"type" => "string"}]}},
        "$ref" => "#/$defs/bar",
        "prefixItems" => [%{"type" => "string"}],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo", "bar", "baz"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with $dynamicRef" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$id" => "https://example.com/unevaluated-items-with-dynamic-ref/derived",
        "$defs" => %{
          "baseSchema" => %{
            "$id" => "./baseSchema",
            "$defs" => %{
              "defaultAddons" => %{
                "$dynamicAnchor" => "addons",
                "$comment" => "Needed to satisfy the bookending requirement"
              }
            },
            "$dynamicRef" => "#addons",
            "type" => "array",
            "$comment" =>
              "unevaluatedItems comes first so it's more likely to catch bugs with implementations that are sensitive to keyword ordering",
            "prefixItems" => [%{"type" => "string"}],
            "unevaluatedItems" => false
          },
          "derived" => %{
            "$dynamicAnchor" => "addons",
            "prefixItems" => [true, %{"type" => "string"}]
          }
        },
        "$ref" => "./baseSchema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated items", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated items", x do
      data = ["foo", "bar", "baz"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems can't see inside cousins" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"prefixItems" => [true]}, %{"unevaluatedItems" => false}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "always fails", x do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "item is evaluated in an uncle schema to unevaluatedItems" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "foo" => %{
            "prefixItems" => [%{"type" => "string"}],
            "unevaluatedItems" => false
          }
        },
        "anyOf" => [
          %{
            "properties" => %{
              "foo" => %{"prefixItems" => [true, %{"type" => "string"}]}
            }
          }
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no extra items", x do
      data = %{"foo" => ["test"]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "uncle keyword evaluation is not significant", x do
      data = %{"foo" => ["test", "test"]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems depends on adjacent contains" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"type" => "string"},
        "prefixItems" => [true],
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "second item is evaluated by contains", x do
      data = [1, "foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "contains fails, second item is not evaluated", x do
      data = [1, 2]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "contains passes, second item is not evaluated", x do
      data = [1, 2, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems depends on multiple nested contains" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"contains" => %{"multipleOf" => 2}},
          %{"contains" => %{"multipleOf" => 3}}
        ],
        "unevaluatedItems" => %{"multipleOf" => 5}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "5 not evaluated, passes unevaluatedItems", x do
      data = [2, 3, 4, 5, 6]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "7 not evaluated, fails unevaluatedItems", x do
      data = [2, 3, 4, 7, 8]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems and contains interact to control item dependency relationship" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{"contains" => %{"const" => "a"}},
        "then" => %{
          "if" => %{"contains" => %{"const" => "b"}},
          "then" => %{"if" => %{"contains" => %{"const" => "c"}}}
        },
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "empty array is valid", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "only a's are valid", x do
      data = ["a", "a"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a's and b's are valid", x do
      data = ["a", "b", "a", "b", "a"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a's, b's and c's are valid", x do
      data = ["c", "a", "c", "c", "b", "a"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "only b's are invalid", x do
      data = ["b", "b"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "only c's are invalid", x do
      data = ["c", "c"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "only b's and c's are invalid", x do
      data = ["c", "b", "c", "b", "c"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "only a's and c's are invalid", x do
      data = ["c", "a", "c", "a", "c"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "non-array instances are valid" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "ignores booleans", x do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores integers", x do
      data = 123
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores floats", x do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores objects", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores strings", x do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores null", x do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems with null instance elements" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedItems" => %{"type" => "null"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null elements", x do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedItems can see annotations from if without then and else" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{"prefixItems" => [%{"const" => "a"}]},
        "unevaluatedItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid in case if is evaluated", x do
      data = ["a"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid in case if is evaluated", x do
      data = ["b"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
