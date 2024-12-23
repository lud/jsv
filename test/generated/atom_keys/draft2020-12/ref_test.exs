# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.RefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/ref.json
  """

  describe "root pointer ref" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: false,
        properties: %{foo: %JSV.Schema{"$ref": "#"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = %{"foo" => false}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "recursive match", x do
      data = %{"foo" => %{"foo" => false}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = %{"bar" => false}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "recursive mismatch", x do
      data = %{"foo" => %{"bar" => false}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "relative pointer ref to object" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          foo: %JSV.Schema{type: "integer"},
          bar: %JSV.Schema{"$ref": "#/properties/foo"}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = %{"bar" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = %{"bar" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "relative pointer ref to array" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        prefixItems: [
          %JSV.Schema{type: "integer"},
          %JSV.Schema{"$ref": "#/prefixItems/0"}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match array", x do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch array", x do
      data = [1, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "escaped pointer ref" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          "percent%field": %JSV.Schema{type: "integer"},
          "slash/field": %JSV.Schema{type: "integer"},
          "tilde~field": %JSV.Schema{type: "integer"}
        },
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          percent: %JSV.Schema{"$ref": "#/$defs/percent%25field"},
          slash: %JSV.Schema{"$ref": "#/$defs/slash~1field"},
          tilde: %JSV.Schema{"$ref": "#/$defs/tilde~0field"}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "slash invalid", x do
      data = %{"slash" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "tilde invalid", x do
      data = %{"tilde" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "percent invalid", x do
      data = %{"percent" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "slash valid", x do
      data = %{"slash" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "tilde valid", x do
      data = %{"tilde" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "percent valid", x do
      data = %{"percent" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nested refs" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          c: %JSV.Schema{"$ref": "#/$defs/b"},
          a: %JSV.Schema{type: "integer"},
          b: %JSV.Schema{"$ref": "#/$defs/a"}
        },
        "$ref": "#/$defs/c",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "nested ref valid", x do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "nested ref invalid", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ref applies alongside sibling keywords" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{reffed: %JSV.Schema{type: "array"}},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{"$ref": "#/$defs/reffed", maxItems: 2}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "ref valid, maxItems valid", x do
      data = %{"foo" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ref valid, maxItems invalid", x do
      data = %{"foo" => [1, 2, 3]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ref invalid", x do
      data = %{"foo" => "string"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "remote ref, containing refs itself" do
    setup do
      json_schema = %JSV.Schema{
        "$ref": "https://json-schema.org/draft/2020-12/schema",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "remote ref valid", x do
      data = %{"minLength" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "remote ref invalid", x do
      data = %{"minLength" => -1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "property named $ref that is not a reference" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %JSV.Schema{"$ref": %JSV.Schema{type: "string"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "property named $ref valid", x do
      data = %{"$ref" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "property named $ref invalid", x do
      data = %{"$ref" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "property named $ref, containing an actual $ref" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{"is-string": %JSV.Schema{type: "string"}},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %JSV.Schema{"$ref": %JSV.Schema{"$ref": "#/$defs/is-string"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "property named $ref valid", x do
      data = %{"$ref" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "property named $ref invalid", x do
      data = %{"$ref" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$ref to boolean schema true" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{bool: true},
        "$ref": "#/$defs/bool",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is valid", x do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$ref to boolean schema false" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{bool: false},
        "$ref": "#/$defs/bool",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", x do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "Recursive references between schemas" do
    setup do
      json_schema = %JSV.Schema{
        type: "object",
        description: "tree of nodes",
        required: ["meta", "nodes"],
        "$defs": %{
          node: %JSV.Schema{
            type: "object",
            description: "node",
            required: ["value"],
            "$id": "http://localhost:1234/draft2020-12/node",
            properties: %{
              value: %JSV.Schema{type: "number"},
              subtree: %JSV.Schema{"$ref": "tree"}
            }
          }
        },
        "$id": "http://localhost:1234/draft2020-12/tree",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          meta: %JSV.Schema{type: "string"},
          nodes: %JSV.Schema{type: "array", items: %JSV.Schema{"$ref": "node"}}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid tree", x do
      data = %{
        "meta" => "root",
        "nodes" => [
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => 1.1}, %{"value" => 1.2}]
            },
            "value" => 1
          },
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => 2.1}, %{"value" => 2.2}]
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
              "nodes" => [%{"value" => "string is invalid"}, %{"value" => 1.2}]
            },
            "value" => 1
          },
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => 2.1}, %{"value" => 2.2}]
            },
            "value" => 2
          }
        ]
      }

      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "refs with quote" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{"foo\"bar": %JSV.Schema{type: "number"}},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{"foo\"bar": %JSV.Schema{"$ref": "#/$defs/foo%22bar"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with numbers is valid", x do
      data = %{"foo\"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "object with strings is invalid", x do
      data = %{"foo\"bar" => "1"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ref creates new scope when adjacent to keywords" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{A: %JSV.Schema{unevaluatedProperties: false}},
        "$ref": "#/$defs/A",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{prop1: %JSV.Schema{type: "string"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "referenced subschema doesn't see annotations from properties", x do
      data = %{"prop1" => "match"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "naive replacement of $ref with its destination is not correct" do
    setup do
      json_schema = %JSV.Schema{
        enum: [%JSV.Schema{"$ref": "#/$defs/a_string"}],
        "$defs": %{a_string: %JSV.Schema{type: "string"}},
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "do not evaluate the $ref inside the enum, matching any string", x do
      data = "this is a string"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "do not evaluate the $ref inside the enum, definition exact match", x do
      data = %{"type" => "string"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "match the enum exactly", x do
      data = %{"$ref" => "#/$defs/a_string"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "refs with relative uris and defs" do
    setup do
      json_schema = %JSV.Schema{
        "$id": "http://example.com/schema-relative-uri-defs1.json",
        "$ref": "schema-relative-uri-defs2.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          foo: %JSV.Schema{
            "$defs": %{
              inner: %JSV.Schema{properties: %{bar: %JSV.Schema{type: "string"}}}
            },
            "$id": "schema-relative-uri-defs2.json",
            "$ref": "#/$defs/inner"
          }
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "invalid on inner field", x do
      data = %{"bar" => "a", "foo" => %{"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid on outer field", x do
      data = %{"bar" => 1, "foo" => %{"bar" => "a"}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid on both fields", x do
      data = %{"bar" => "a", "foo" => %{"bar" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "relative refs with absolute uris and defs" do
    setup do
      json_schema = %JSV.Schema{
        "$id": "http://example.com/schema-refs-absolute-uris-defs1.json",
        "$ref": "schema-refs-absolute-uris-defs2.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          foo: %JSV.Schema{
            "$defs": %{
              inner: %JSV.Schema{properties: %{bar: %JSV.Schema{type: "string"}}}
            },
            "$id": "http://example.com/schema-refs-absolute-uris-defs2.json",
            "$ref": "#/$defs/inner"
          }
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "invalid on inner field", x do
      data = %{"bar" => "a", "foo" => %{"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid on outer field", x do
      data = %{"bar" => 1, "foo" => %{"bar" => "a"}}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid on both fields", x do
      data = %{"bar" => "a", "foo" => %{"bar" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$id must be resolved against nearest parent, not just immediate parent" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          x: %JSV.Schema{
            not: %JSV.Schema{
              "$defs": %{y: %JSV.Schema{type: "number", "$id": "d.json"}}
            },
            "$id": "http://example.com/b/c.json"
          }
        },
        "$id": "http://example.com/a.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{"$ref": "http://example.com/b/d.json"}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-number is invalid", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "order of evaluation: $id and $ref" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "$id must be evaluated before $ref to get the proper $ref destination",
        "$defs": %{
          bigint: %JSV.Schema{
            maximum: 10,
            "$comment": "canonical uri: https://example.com/ref-and-id1/int.json",
            "$id": "int.json"
          },
          smallint: %JSV.Schema{
            maximum: 2,
            "$comment": "canonical uri: https://example.com/ref-and-id1-int.json",
            "$id": "/draft2020-12/ref-and-id1-int.json"
          }
        },
        "$id": "https://example.com/draft2020-12/ref-and-id1/base.json",
        "$ref": "int.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "data is valid against first definition", x do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "data is invalid against first definition", x do
      data = 50
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "order of evaluation: $id and $anchor and $ref" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "$id must be evaluated before $ref to get the proper $ref destination",
        "$defs": %{
          bigint: %JSV.Schema{
            maximum: 10,
            "$anchor": "bigint",
            "$comment":
              "canonical uri: /ref-and-id2/base.json#/$defs/bigint; another valid uri for this location: /ref-and-id2/base.json#bigint"
          },
          smallint: %JSV.Schema{
            maximum: 2,
            "$anchor": "bigint",
            "$comment":
              "canonical uri: https://example.com/ref-and-id2#/$defs/smallint; another valid uri for this location: https://example.com/ref-and-id2/#bigint",
            "$id": "https://example.com/draft2020-12/ref-and-id2/"
          }
        },
        "$id": "https://example.com/draft2020-12/ref-and-id2/base.json",
        "$ref": "#bigint",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "data is valid against first definition", x do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "data is invalid against first definition", x do
      data = 50
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "simple URN base URI with $ref via the URN" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "URIs do not have to have HTTP(s) schemes",
        "$id": "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        minimum: 30,
        properties: %{
          foo: %JSV.Schema{"$ref": "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed"}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid under the URN IDed schema", x do
      data = %{"foo" => 37}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid under the URN IDed schema", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "simple URN base URI with JSON pointer" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "URIs do not have to have HTTP(s) schemes",
        "$defs": %{bar: %JSV.Schema{type: "string"}},
        "$id": "urn:uuid:deadbeef-1234-00ff-ff00-4321feebdaed",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{"$ref": "#/$defs/bar"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "URN base URI with NSS" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "RFC 8141 §2.2",
        "$defs": %{bar: %JSV.Schema{type: "string"}},
        "$id": "urn:example:1/406/47452/2",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{"$ref": "#/$defs/bar"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "URN base URI with r-component" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "RFC 8141 §2.3.1",
        "$defs": %{bar: %JSV.Schema{type: "string"}},
        "$id": "urn:example:foo-bar-baz-qux?+CCResolve:cc=uk",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{"$ref": "#/$defs/bar"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "URN base URI with q-component" do
    setup do
      json_schema = %JSV.Schema{
        "$comment": "RFC 8141 §2.3.2",
        "$defs": %{bar: %JSV.Schema{type: "string"}},
        "$id": "urn:example:weather?=op=map&lat=39.56&lon=-104.85&datetime=1969-07-21T02:56:15Z",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %JSV.Schema{"$ref": "#/$defs/bar"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "URN base URI with URN and JSON pointer ref" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{bar: %JSV.Schema{type: "string"}},
        "$id": "urn:uuid:deadbeef-1234-0000-0000-4321feebdaed",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          foo: %JSV.Schema{
            "$ref": "urn:uuid:deadbeef-1234-0000-0000-4321feebdaed#/$defs/bar"
          }
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "URN base URI with URN and anchor ref" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{bar: %JSV.Schema{type: "string", "$anchor": "something"}},
        "$id": "urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          foo: %JSV.Schema{
            "$ref": "urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed#something"
          }
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "URN ref with nested pointer ref" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          foo: %JSV.Schema{
            "$defs": %{bar: %JSV.Schema{type: "string"}},
            "$id": "urn:uuid:deadbeef-4321-ffff-ffff-1234feebdaed",
            "$ref": "#/$defs/bar"
          }
        },
        "$ref": "urn:uuid:deadbeef-4321-ffff-ffff-1234feebdaed",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = "bar"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-string is invalid", x do
      data = 12
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ref to if" do
    setup do
      json_schema = %JSV.Schema{
        if: %JSV.Schema{type: "integer", "$id": "http://example.com/ref/if"},
        "$ref": "http://example.com/ref/if",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", x do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an integer is valid", x do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ref to then" do
    setup do
      json_schema = %JSV.Schema{
        then: %JSV.Schema{type: "integer", "$id": "http://example.com/ref/then"},
        "$ref": "http://example.com/ref/then",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", x do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an integer is valid", x do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ref to else" do
    setup do
      json_schema = %JSV.Schema{
        else: %JSV.Schema{type: "integer", "$id": "http://example.com/ref/else"},
        "$ref": "http://example.com/ref/else",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", x do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an integer is valid", x do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ref with absolute-path-reference" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          a: %JSV.Schema{
            type: "number",
            "$id": "http://example.com/ref/absref/foobar.json"
          },
          b: %JSV.Schema{
            type: "string",
            "$id": "http://example.com/absref/foobar.json"
          }
        },
        "$id": "http://example.com/ref/absref.json",
        "$ref": "/absref/foobar.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", x do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an integer is invalid", x do
      data = 12
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$id with file URI still resolves pointers - *nix" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{foo: %JSV.Schema{type: "number"}},
        "$id": "file:///folder/file.json",
        "$ref": "#/$defs/foo",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-number is invalid", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$id with file URI still resolves pointers - windows" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{foo: %JSV.Schema{type: "number"}},
        "$id": "file:///c:/folder/file.json",
        "$ref": "#/$defs/foo",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-number is invalid", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "empty tokens in $ref json-pointer" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{"": %JSV.Schema{"$defs": %{"": %JSV.Schema{type: "number"}}}},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [%JSV.Schema{"$ref": "#/$defs//$defs/"}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-number is invalid", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
