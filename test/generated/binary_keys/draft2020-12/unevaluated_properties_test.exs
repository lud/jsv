# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.UnevaluatedPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/unevaluatedProperties.json
  """

  describe "unevaluatedProperties true" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "unevaluatedProperties" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties schema" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "unevaluatedProperties" => %{"type" => "string", "minLength" => 3}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with valid unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with invalid unevaluated properties", x do
      data = %{"foo" => "fo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties false" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with adjacent properties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with adjacent patternProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "patternProperties" => %{"^foo" => %{"type" => "string"}},
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with adjacent additionalProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "additionalProperties" => true,
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with additional properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with nested properties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [%{"properties" => %{"bar" => %{"type" => "string"}}}],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with additional properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with nested patternProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [%{"patternProperties" => %{"^bar" => %{"type" => "string"}}}],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with additional properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with nested additionalProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [%{"additionalProperties" => true}],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with additional properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with nested unevaluatedProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [%{"unevaluatedProperties" => true}],
        "unevaluatedProperties" => %{"type" => "string", "maxLength" => 2}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with anyOf" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "anyOf" => [
          %{"properties" => %{"bar" => %{"const" => "bar"}}, "required" => ["bar"]},
          %{"properties" => %{"baz" => %{"const" => "baz"}}, "required" => ["baz"]},
          %{"properties" => %{"quux" => %{"const" => "quux"}}, "required" => ["quux"]}
        ],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when one matches and has no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when one matches and has unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "not-baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when two match and has no unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when two match and has unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo", "quux" => "not-quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with oneOf" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "oneOf" => [
          %{"properties" => %{"bar" => %{"const" => "bar"}}, "required" => ["bar"]},
          %{"properties" => %{"baz" => %{"const" => "baz"}}, "required" => ["baz"]}
        ],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo", "quux" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with not" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "not" => %{
          "not" => %{
            "properties" => %{"bar" => %{"const" => "bar"}},
            "required" => ["bar"]
          }
        },
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with if/then/else" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "else" => %{
          "properties" => %{"baz" => %{"type" => "string"}},
          "required" => ["baz"]
        },
        "if" => %{
          "properties" => %{"foo" => %{"const" => "then"}},
          "required" => ["foo"]
        },
        "then" => %{
          "properties" => %{"bar" => %{"type" => "string"}},
          "required" => ["bar"]
        },
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if is true and has no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "then"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is true and has unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is false and has no unevaluated properties", x do
      data = %{"baz" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is false and has unevaluated properties", x do
      data = %{"baz" => "baz", "foo" => "else"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with if/then/else, then not defined" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "else" => %{
          "properties" => %{"baz" => %{"type" => "string"}},
          "required" => ["baz"]
        },
        "if" => %{
          "properties" => %{"foo" => %{"const" => "then"}},
          "required" => ["foo"]
        },
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if is true and has no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is true and has unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is false and has no unevaluated properties", x do
      data = %{"baz" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is false and has unevaluated properties", x do
      data = %{"baz" => "baz", "foo" => "else"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with if/then/else, else not defined" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "if" => %{
          "properties" => %{"foo" => %{"const" => "then"}},
          "required" => ["foo"]
        },
        "then" => %{
          "properties" => %{"bar" => %{"type" => "string"}},
          "required" => ["bar"]
        },
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if is true and has no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "then"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is true and has unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is false and has no unevaluated properties", x do
      data = %{"baz" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "when if is false and has unevaluated properties", x do
      data = %{"baz" => "baz", "foo" => "else"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with dependentSchemas" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "dependentSchemas" => %{
          "foo" => %{
            "properties" => %{"bar" => %{"const" => "bar"}},
            "required" => ["bar"]
          }
        },
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with boolean schemas" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [true],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with $ref" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$defs" => %{"bar" => %{"properties" => %{"bar" => %{"type" => "string"}}}},
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "$ref" => "#/$defs/bar",
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties before $ref" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$defs" => %{"bar" => %{"properties" => %{"bar" => %{"type" => "string"}}}},
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "$ref" => "#/$defs/bar",
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties with $dynamicRef" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$id" => "https://example.com/unevaluated-properties-with-dynamic-ref/derived",
        "$defs" => %{
          "baseSchema" => %{
            "$id" => "./baseSchema",
            "$defs" => %{
              "defaultAddons" => %{
                "$comment" => "Needed to satisfy the bookending requirement",
                "$dynamicAnchor" => "addons"
              }
            },
            "type" => "object",
            "properties" => %{"foo" => %{"type" => "string"}},
            "$comment" =>
              "unevaluatedProperties comes first so it's more likely to catch bugs with implementations that are sensitive to keyword ordering",
            "$dynamicRef" => "#addons",
            "unevaluatedProperties" => false
          },
          "derived" => %{
            "properties" => %{"bar" => %{"type" => "string"}},
            "$dynamicAnchor" => "addons"
          }
        },
        "$ref" => "./baseSchema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with unevaluated properties", x do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties can't see inside cousins" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"properties" => %{"foo" => true}},
          %{"unevaluatedProperties" => false}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "always fails", x do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties can't see inside cousins (reverse order)" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"unevaluatedProperties" => false},
          %{"properties" => %{"foo" => true}}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "always fails", x do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nested unevaluatedProperties, outer false, inner true, properties outside" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [%{"unevaluatedProperties" => true}],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nested unevaluatedProperties, outer false, inner true, properties inside" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "allOf" => [
          %{
            "properties" => %{"foo" => %{"type" => "string"}},
            "unevaluatedProperties" => true
          }
        ],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nested unevaluatedProperties, outer true, inner false, properties outside" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"foo" => %{"type" => "string"}},
        "allOf" => [%{"unevaluatedProperties" => false}],
        "unevaluatedProperties" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nested unevaluatedProperties, outer true, inner false, properties inside" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "allOf" => [
          %{
            "properties" => %{"foo" => %{"type" => "string"}},
            "unevaluatedProperties" => false
          }
        ],
        "unevaluatedProperties" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "cousin unevaluatedProperties, true and false, true with properties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "allOf" => [
          %{
            "properties" => %{"foo" => %{"type" => "string"}},
            "unevaluatedProperties" => true
          },
          %{"unevaluatedProperties" => false}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "cousin unevaluatedProperties, true and false, false with properties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "allOf" => [
          %{"unevaluatedProperties" => true},
          %{
            "properties" => %{"foo" => %{"type" => "string"}},
            "unevaluatedProperties" => false
          }
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", x do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "with nested unevaluated properties", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "property is evaluated in an uncle schema to unevaluatedProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{
          "foo" => %{
            "type" => "object",
            "properties" => %{"bar" => %{"type" => "string"}},
            "unevaluatedProperties" => false
          }
        },
        "anyOf" => [
          %{
            "properties" => %{
              "foo" => %{"properties" => %{"faz" => %{"type" => "string"}}}
            }
          }
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no extra properties", x do
      data = %{"foo" => %{"bar" => "test"}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "uncle keyword evaluation is not significant", x do
      data = %{"foo" => %{"bar" => "test", "faz" => "test"}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "in-place applicator siblings, allOf has unevaluated" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "allOf" => [
          %{"properties" => %{"foo" => true}, "unevaluatedProperties" => false}
        ],
        "anyOf" => [%{"properties" => %{"bar" => true}}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "base case: both properties present", x do
      data = %{"bar" => 1, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "in place applicator siblings, bar is missing", x do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "in place applicator siblings, foo is missing", x do
      data = %{"bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "in-place applicator siblings, anyOf has unevaluated" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "allOf" => [%{"properties" => %{"foo" => true}}],
        "anyOf" => [
          %{"properties" => %{"bar" => true}, "unevaluatedProperties" => false}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "base case: both properties present", x do
      data = %{"bar" => 1, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "in place applicator siblings, bar is missing", x do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "in place applicator siblings, foo is missing", x do
      data = %{"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties + single cyclic ref" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => %{"x" => %{"$ref" => "#"}},
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Empty is valid", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Single is valid", x do
      data = %{"x" => %{}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Unevaluated on 1st level is invalid", x do
      data = %{"x" => %{}, "y" => %{}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Nested is valid", x do
      data = %{"x" => %{"x" => %{}}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Unevaluated on 2nd level is invalid", x do
      data = %{"x" => %{"x" => %{}, "y" => %{}}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Deep nested is valid", x do
      data = %{"x" => %{"x" => %{"x" => %{}}}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Unevaluated on 3rd level is invalid", x do
      data = %{"x" => %{"x" => %{"x" => %{}, "y" => %{}}}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties + ref inside allOf / oneOf" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$defs" => %{
          "one" => %{"properties" => %{"a" => true}},
          "two" => %{"properties" => %{"x" => true}, "required" => ["x"]}
        },
        "allOf" => [
          %{"$ref" => "#/$defs/one"},
          %{"properties" => %{"b" => true}},
          %{
            "oneOf" => [
              %{"$ref" => "#/$defs/two"},
              %{"properties" => %{"y" => true}, "required" => ["y"]}
            ]
          }
        ],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Empty is invalid (no x or y)", x do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a and b are invalid (no x or y)", x do
      data = %{"a" => 1, "b" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "x and y are invalid", x do
      data = %{"x" => 1, "y" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a and x are valid", x do
      data = %{"a" => 1, "x" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a and y are valid", x do
      data = %{"a" => 1, "y" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a and b and x are valid", x do
      data = %{"a" => 1, "b" => 1, "x" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a and b and y are valid", x do
      data = %{"a" => 1, "b" => 1, "y" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a and b and x and y are invalid", x do
      data = %{"a" => 1, "b" => 1, "x" => 1, "y" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "dynamic evalation inside nested refs" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$defs" => %{
          "one" => %{
            "oneOf" => [
              %{"$ref" => "#/$defs/two"},
              %{"properties" => %{"b" => true}, "required" => ["b"]},
              %{"required" => ["xx"], "patternProperties" => %{"x" => true}},
              %{"required" => ["all"], "unevaluatedProperties" => true}
            ]
          },
          "two" => %{
            "oneOf" => [
              %{"properties" => %{"c" => true}, "required" => ["c"]},
              %{"properties" => %{"d" => true}, "required" => ["d"]}
            ]
          }
        },
        "oneOf" => [
          %{"$ref" => "#/$defs/one"},
          %{"properties" => %{"a" => true}, "required" => ["a"]}
        ],
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Empty is invalid", x do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a is valid", x do
      data = %{"a" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "b is valid", x do
      data = %{"b" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "c is valid", x do
      data = %{"c" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "d is valid", x do
      data = %{"d" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a + b is invalid", x do
      data = %{"a" => 1, "b" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a + c is invalid", x do
      data = %{"a" => 1, "c" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a + d is invalid", x do
      data = %{"a" => 1, "d" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "b + c is invalid", x do
      data = %{"b" => 1, "c" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "b + d is invalid", x do
      data = %{"b" => 1, "d" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "c + d is invalid", x do
      data = %{"c" => 1, "d" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx is valid", x do
      data = %{"xx" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx + foox is valid", x do
      data = %{"foox" => 1, "xx" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx + foo is invalid", x do
      data = %{"foo" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx + a is invalid", x do
      data = %{"a" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx + b is invalid", x do
      data = %{"b" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx + c is invalid", x do
      data = %{"c" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "xx + d is invalid", x do
      data = %{"d" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all is valid", x do
      data = %{"all" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all + foo is valid", x do
      data = %{"all" => 1, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all + a is invalid", x do
      data = %{"a" => 1, "all" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "non-object instances are valid" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedProperties" => false
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

    test "ignores arrays", x do
      data = []
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

  describe "unevaluatedProperties with null valued instance properties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedProperties" => %{"type" => "null"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null valued properties", x do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties not affected by propertyNames" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "propertyNames" => %{"maxLength" => 1},
        "unevaluatedProperties" => %{"type" => "number"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows only number properties", x do
      data = %{"a" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "string property is invalid", x do
      data = %{"a" => "b"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "unevaluatedProperties can see annotations from if without then and else" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{"patternProperties" => %{"foo" => %{"type" => "string"}}},
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid in case if is evaluated", x do
      data = %{"foo" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid in case if is evaluated", x do
      data = %{"bar" => "a"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "dependentSchemas with unevaluatedProperties" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo2" => %{}},
        "dependentSchemas" => %{
          "foo" => %{},
          "foo2" => %{"properties" => %{"bar" => %{}}}
        },
        "unevaluatedProperties" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "unevaluatedProperties doesn't consider dependentSchemas", x do
      data = %{"foo" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unevaluatedProperties doesn't see bar when foo2 is absent", x do
      data = %{"bar" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unevaluatedProperties sees bar when foo2 is present", x do
      data = %{"bar" => "", "foo2" => ""}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
