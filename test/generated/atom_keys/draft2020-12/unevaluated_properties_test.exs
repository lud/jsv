# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.UnevaluatedPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/unevaluatedProperties.json
  """

  describe "unevaluatedProperties true" do
    setup do
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: true
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: %JSV.Schema{type: "string", minLength: 3}
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        patternProperties: %{"^foo": %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: true,
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{properties: %{bar: %JSV.Schema{type: "string"}}}],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{patternProperties: %{"^bar": %JSV.Schema{type: "string"}}}
        ],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{additionalProperties: true}],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{unevaluatedProperties: true}],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: %JSV.Schema{type: "string", maxLength: 2}
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        anyOf: [
          %JSV.Schema{required: ["bar"], properties: %{bar: %{const: "bar"}}},
          %JSV.Schema{required: ["baz"], properties: %{baz: %{const: "baz"}}},
          %JSV.Schema{required: ["quux"], properties: %{quux: %{const: "quux"}}}
        ],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        oneOf: [
          %JSV.Schema{required: ["bar"], properties: %{bar: %{const: "bar"}}},
          %JSV.Schema{required: ["baz"], properties: %{baz: %{const: "baz"}}}
        ],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        not: %JSV.Schema{
          not: %JSV.Schema{required: ["bar"], properties: %{bar: %{const: "bar"}}}
        },
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        else: %JSV.Schema{
          required: ["baz"],
          properties: %{baz: %JSV.Schema{type: "string"}}
        },
        if: %JSV.Schema{required: ["foo"], properties: %{foo: %{const: "then"}}},
        then: %JSV.Schema{
          required: ["bar"],
          properties: %{bar: %JSV.Schema{type: "string"}}
        },
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        else: %JSV.Schema{
          required: ["baz"],
          properties: %{baz: %JSV.Schema{type: "string"}}
        },
        if: %JSV.Schema{required: ["foo"], properties: %{foo: %{const: "then"}}},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        if: %JSV.Schema{required: ["foo"], properties: %{foo: %{const: "then"}}},
        then: %JSV.Schema{
          required: ["bar"],
          properties: %{bar: %JSV.Schema{type: "string"}}
        },
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        dependentSchemas: %{
          foo: %JSV.Schema{required: ["bar"], properties: %{bar: %{const: "bar"}}}
        },
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [true],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$defs": %{bar: %JSV.Schema{properties: %{bar: %JSV.Schema{type: "string"}}}},
        "$ref": "#/$defs/bar",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$defs": %{bar: %JSV.Schema{properties: %{bar: %JSV.Schema{type: "string"}}}},
        "$ref": "#/$defs/bar",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        "$defs": %{
          baseSchema: %JSV.Schema{
            type: "object",
            "$comment":
              "unevaluatedProperties comes first so it's more likely to catch bugs with implementations that are sensitive to keyword ordering",
            "$defs": %{
              defaultAddons: %JSV.Schema{
                "$comment": "Needed to satisfy the bookending requirement",
                "$dynamicAnchor": "addons"
              }
            },
            "$dynamicRef": "#addons",
            "$id": "./baseSchema",
            properties: %{foo: %JSV.Schema{type: "string"}},
            unevaluatedProperties: false
          },
          derived: %JSV.Schema{
            "$dynamicAnchor": "addons",
            properties: %{bar: %JSV.Schema{type: "string"}}
          }
        },
        "$id": "https://example.com/unevaluated-properties-with-dynamic-ref/derived",
        "$ref": "./baseSchema",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
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
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{properties: %{foo: true}},
          %JSV.Schema{unevaluatedProperties: false}
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
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{unevaluatedProperties: false},
          %JSV.Schema{properties: %{foo: true}}
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{unevaluatedProperties: true}],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{
            properties: %{foo: %JSV.Schema{type: "string"}},
            unevaluatedProperties: true
          }
        ],
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{unevaluatedProperties: false}],
        properties: %{foo: %JSV.Schema{type: "string"}},
        unevaluatedProperties: true
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{
            properties: %{foo: %JSV.Schema{type: "string"}},
            unevaluatedProperties: false
          }
        ],
        unevaluatedProperties: true
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{
            properties: %{foo: %JSV.Schema{type: "string"}},
            unevaluatedProperties: true
          },
          %JSV.Schema{unevaluatedProperties: false}
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{unevaluatedProperties: true},
          %JSV.Schema{
            properties: %{foo: %JSV.Schema{type: "string"}},
            unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        anyOf: [
          %JSV.Schema{
            properties: %{
              foo: %JSV.Schema{properties: %{faz: %JSV.Schema{type: "string"}}}
            }
          }
        ],
        properties: %{
          foo: %JSV.Schema{
            type: "object",
            properties: %{bar: %JSV.Schema{type: "string"}},
            unevaluatedProperties: false
          }
        }
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{properties: %{foo: true}, unevaluatedProperties: false}],
        anyOf: [%JSV.Schema{properties: %{bar: true}}]
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{properties: %{foo: true}}],
        anyOf: [%JSV.Schema{properties: %{bar: true}, unevaluatedProperties: false}]
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
      json_schema = %JSV.Schema{
        type: "object",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{x: %JSV.Schema{"$ref": "#"}},
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        "$defs": %{
          one: %JSV.Schema{properties: %{a: true}},
          two: %JSV.Schema{required: ["x"], properties: %{x: true}}
        },
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{"$ref": "#/$defs/one"},
          %JSV.Schema{properties: %{b: true}},
          %JSV.Schema{
            oneOf: [
              %JSV.Schema{"$ref": "#/$defs/two"},
              %JSV.Schema{required: ["y"], properties: %{y: true}}
            ]
          }
        ],
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        "$defs": %{
          one: %JSV.Schema{
            oneOf: [
              %JSV.Schema{"$ref": "#/$defs/two"},
              %JSV.Schema{required: ["b"], properties: %{b: true}},
              %JSV.Schema{required: ["xx"], patternProperties: %{x: true}},
              %JSV.Schema{required: ["all"], unevaluatedProperties: true}
            ]
          },
          two: %JSV.Schema{
            oneOf: [
              %JSV.Schema{required: ["c"], properties: %{c: true}},
              %JSV.Schema{required: ["d"], properties: %{d: true}}
            ]
          }
        },
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        oneOf: [
          %JSV.Schema{"$ref": "#/$defs/one"},
          %JSV.Schema{required: ["a"], properties: %{a: true}}
        ],
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: %JSV.Schema{type: "null"}
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
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        propertyNames: %JSV.Schema{maxLength: 1},
        unevaluatedProperties: %JSV.Schema{type: "number"}
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
      json_schema = %JSV.Schema{
        if: %JSV.Schema{patternProperties: %{foo: %JSV.Schema{type: "string"}}},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
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
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        dependentSchemas: %{
          foo: %JSV.Schema{},
          foo2: %JSV.Schema{properties: %{bar: %JSV.Schema{}}}
        },
        properties: %{foo2: %JSV.Schema{}},
        unevaluatedProperties: false
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
