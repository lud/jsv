# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.DynamicRefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/dynamicRef.json
  """

  describe "A $dynamicRef to a $dynamicAnchor in the same schema resource behaves like a normal $ref to an $anchor" do
    setup do
      json_schema = %JSV.Schema{
        type: "array",
        items: %JSV.Schema{"$dynamicRef": "#items"},
        "$defs": %{foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"}},
        "$id": "https://test.json-schema.org/dynamicRef-dynamicAnchor-same-schema/root",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "An array of strings is valid", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "An array containing non-strings is invalid", x do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef to an $anchor in the same schema resource behaves like a normal $ref to an $anchor" do
    setup do
      json_schema = %JSV.Schema{
        type: "array",
        items: %JSV.Schema{"$dynamicRef": "#items"},
        "$defs": %{foo: %JSV.Schema{type: "string", "$anchor": "items"}},
        "$id": "https://test.json-schema.org/dynamicRef-anchor-same-schema/root",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "An array of strings is valid", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "An array containing non-strings is invalid", x do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $ref to a $dynamicAnchor in the same schema resource behaves like a normal $ref to an $anchor" do
    setup do
      json_schema = %JSV.Schema{
        type: "array",
        items: %JSV.Schema{"$ref": "#items"},
        "$defs": %{foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"}},
        "$id": "https://test.json-schema.org/ref-dynamicAnchor-same-schema/root",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "An array of strings is valid", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "An array containing non-strings is invalid", x do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef resolves to the first $dynamicAnchor still in scope that is encountered when the schema is evaluated" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          list: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$dynamicRef": "#items"},
            "$defs": %JSV.Schema{
              items: %JSV.Schema{
                "$comment": "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor": "items"
              }
            },
            "$id": "list"
          },
          foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"}
        },
        "$id": "https://test.json-schema.org/typical-dynamic-resolution/root",
        "$ref": "list",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "An array of strings is valid", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "An array containing non-strings is invalid", x do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef without anchor in fragment behaves identical to $ref" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          list: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$dynamicRef": "#/$defs/items"},
            "$defs": %JSV.Schema{
              items: %JSV.Schema{
                type: "number",
                "$comment": "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor": "items"
              }
            },
            "$id": "list"
          },
          foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"}
        },
        "$id": "https://test.json-schema.org/dynamicRef-without-anchor/root",
        "$ref": "list",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "An array of strings is invalid", x do
      data = ["foo", "bar"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "An array of numbers is valid", x do
      data = [24, 42]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef with intermediate scopes that don't include a matching $dynamicAnchor does not affect dynamic scope resolution" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          list: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$dynamicRef": "#items"},
            "$defs": %JSV.Schema{
              items: %JSV.Schema{
                "$comment": "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor": "items"
              }
            },
            "$id": "list"
          },
          foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"},
          "intermediate-scope": %JSV.Schema{
            "$id": "intermediate-scope",
            "$ref": "list"
          }
        },
        "$id": "https://test.json-schema.org/dynamic-resolution-with-intermediate-scopes/root",
        "$ref": "intermediate-scope",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "An array of strings is valid", x do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "An array containing non-strings is invalid", x do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "An $anchor with the same name as a $dynamicAnchor is not used for dynamic scope resolution" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          list: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$dynamicRef": "#items"},
            "$defs": %JSV.Schema{
              items: %JSV.Schema{
                "$comment": "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor": "items"
              }
            },
            "$id": "list"
          },
          foo: %JSV.Schema{type: "string", "$anchor": "items"}
        },
        "$id": "https://test.json-schema.org/dynamic-resolution-ignores-anchors/root",
        "$ref": "list",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Any array is valid", x do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef without a matching $dynamicAnchor in the same schema resource behaves like a normal $ref to $anchor" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          list: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$dynamicRef": "#items"},
            "$defs": %JSV.Schema{
              items: %JSV.Schema{
                "$anchor": "items",
                "$comment":
                  "This is only needed to give the reference somewhere to resolve to when it behaves like $ref"
              }
            },
            "$id": "list"
          },
          foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"}
        },
        "$id": "https://test.json-schema.org/dynamic-resolution-without-bookend/root",
        "$ref": "list",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Any array is valid", x do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef with a non-matching $dynamicAnchor in the same schema resource behaves like a normal $ref to $anchor" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          list: %JSV.Schema{
            type: "array",
            items: %JSV.Schema{"$dynamicRef": "#items"},
            "$defs": %JSV.Schema{
              items: %JSV.Schema{
                "$anchor": "items",
                "$comment":
                  "This is only needed to give the reference somewhere to resolve to when it behaves like $ref",
                "$dynamicAnchor": "foo"
              }
            },
            "$id": "list"
          },
          foo: %JSV.Schema{type: "string", "$dynamicAnchor": "items"}
        },
        "$id": "https://test.json-schema.org/unmatched-dynamic-anchor/root",
        "$ref": "list",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Any array is valid", x do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef that initially resolves to a schema with a matching $dynamicAnchor resolves to the first $dynamicAnchor in the dynamic scope" do
    setup do
      json_schema = %JSV.Schema{
        type: "object",
        "$defs": %{
          extended: %JSV.Schema{
            type: "object",
            "$dynamicAnchor": "meta",
            "$id": "extended",
            properties: %{bar: %JSV.Schema{"$ref": "bar"}}
          },
          bar: %JSV.Schema{
            type: "object",
            "$id": "bar",
            properties: %{baz: %JSV.Schema{"$dynamicRef": "extended#meta"}}
          }
        },
        "$dynamicAnchor": "meta",
        "$id": "https://test.json-schema.org/relative-dynamic-reference/root",
        "$ref": "extended",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %{const: "pass"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "The recursive part is valid against the root", x do
      data = %{"bar" => %{"baz" => %{"foo" => "pass"}}, "foo" => "pass"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "The recursive part is not valid against the root", x do
      data = %{"bar" => %{"baz" => %{"foo" => "fail"}}, "foo" => "pass"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "A $dynamicRef that initially resolves to a schema without a matching $dynamicAnchor behaves like a normal $ref to $anchor" do
    setup do
      json_schema = %JSV.Schema{
        type: "object",
        "$defs": %{
          extended: %JSV.Schema{
            type: "object",
            "$anchor": "meta",
            "$id": "extended",
            properties: %{bar: %JSV.Schema{"$ref": "bar"}}
          },
          bar: %JSV.Schema{
            type: "object",
            "$id": "bar",
            properties: %{baz: %JSV.Schema{"$dynamicRef": "extended#meta"}}
          }
        },
        "$dynamicAnchor": "meta",
        "$id": "https://test.json-schema.org/relative-dynamic-reference-without-bookend/root",
        "$ref": "extended",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %{const: "pass"}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "The recursive part doesn't need to validate against the root", x do
      data = %{"bar" => %{"baz" => %{"foo" => "fail"}}, "foo" => "pass"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "multiple dynamic paths to the $dynamicRef keyword" do
    setup do
      json_schema = %JSV.Schema{
        else: %JSV.Schema{"$ref": "stringList"},
        if: %JSV.Schema{
          required: ["kindOfList"],
          properties: %{kindOfList: %{const: "numbers"}}
        },
        then: %JSV.Schema{"$ref": "numberList"},
        "$defs": %{
          genericList: %JSV.Schema{
            "$defs": %{
              defaultItemType: %JSV.Schema{
                "$comment": "Only needed to satisfy bookending requirement",
                "$dynamicAnchor": "itemType"
              }
            },
            "$id": "genericList",
            properties: %{
              list: %JSV.Schema{items: %JSV.Schema{"$dynamicRef": "#itemType"}}
            }
          },
          numberList: %JSV.Schema{
            "$defs": %{
              itemType: %JSV.Schema{type: "number", "$dynamicAnchor": "itemType"}
            },
            "$id": "numberList",
            "$ref": "genericList"
          },
          stringList: %JSV.Schema{
            "$defs": %{
              itemType: %JSV.Schema{type: "string", "$dynamicAnchor": "itemType"}
            },
            "$id": "stringList",
            "$ref": "genericList"
          }
        },
        "$id": "https://test.json-schema.org/dynamic-ref-with-multiple-paths/main",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number list with number values", x do
      data = %{"kindOfList" => "numbers", "list" => [1.1]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "number list with string values", x do
      data = %{"kindOfList" => "numbers", "list" => ["foo"]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "string list with number values", x do
      data = %{"kindOfList" => "strings", "list" => [1.1]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "string list with string values", x do
      data = %{"kindOfList" => "strings", "list" => ["foo"]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "after leaving a dynamic scope, it is not used by a $dynamicRef" do
    setup do
      json_schema = %JSV.Schema{
        if: %JSV.Schema{
          "$defs": %{
            thingy: %JSV.Schema{
              type: "number",
              "$comment": "this is first_scope#thingy",
              "$dynamicAnchor": "thingy"
            }
          },
          "$id": "first_scope"
        },
        then: %JSV.Schema{
          "$defs": %{
            thingy: %JSV.Schema{
              type: "null",
              "$comment": "this is second_scope#thingy, the final destination of the $dynamicRef",
              "$dynamicAnchor": "thingy"
            }
          },
          "$id": "second_scope",
          "$ref": "start"
        },
        "$defs": %{
          start: %JSV.Schema{
            "$comment": "this is the landing spot from $ref",
            "$dynamicRef": "inner_scope#thingy",
            "$id": "start"
          },
          thingy: %JSV.Schema{
            type: "string",
            "$comment": "this is the first stop for the $dynamicRef",
            "$dynamicAnchor": "thingy",
            "$id": "inner_scope"
          }
        },
        "$id": "https://test.json-schema.org/dynamic-ref-leaving-dynamic-scope/main",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "string matches /$defs/thingy, but the $dynamicRef does not stop here", x do
      data = "a string"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "first_scope is not in dynamic scope for the $dynamicRef", x do
      data = 42
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "/then/$defs/thingy is the final stop for the $dynamicRef", x do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "strict-tree schema, guards against misspelled properties" do
    setup do
      json_schema = %JSV.Schema{
        "$dynamicAnchor": "node",
        "$id": "http://localhost:1234/draft2020-12/strict-tree.json",
        "$ref": "tree.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        unevaluatedProperties: false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "instance with misspelled field", x do
      data = %{"children" => [%{"daat" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "instance with correct field", x do
      data = %{"children" => [%{"data" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "tests for implementation dynamic anchor and reference link" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          elements: %JSV.Schema{
            required: ["a"],
            "$dynamicAnchor": "elements",
            additionalProperties: false,
            properties: %{a: true}
          }
        },
        "$id": "http://localhost:1234/draft2020-12/strict-extendible.json",
        "$ref": "extendible-dynamic-ref.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "incorrect parent schema", x do
      data = %{"a" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "incorrect extended schema", x do
      data = %{"elements" => [%{"b" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "correct extended schema", x do
      data = %{"elements" => [%{"a" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$ref and $dynamicAnchor are independent of order - $defs first" do
    setup do
      json_schema = %JSV.Schema{
        "$id": "http://localhost:1234/draft2020-12/strict-extendible-allof-defs-first.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{"$ref": "extendible-dynamic-ref.json"},
          %JSV.Schema{
            "$defs": %{
              elements: %JSV.Schema{
                required: ["a"],
                "$dynamicAnchor": "elements",
                additionalProperties: false,
                properties: %{a: true}
              }
            }
          }
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "incorrect parent schema", x do
      data = %{"a" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "incorrect extended schema", x do
      data = %{"elements" => [%{"b" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "correct extended schema", x do
      data = %{"elements" => [%{"a" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$ref and $dynamicAnchor are independent of order - $ref first" do
    setup do
      json_schema = %JSV.Schema{
        "$id": "http://localhost:1234/draft2020-12/strict-extendible-allof-ref-first.json",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        allOf: [
          %JSV.Schema{
            "$defs": %{
              elements: %JSV.Schema{
                required: ["a"],
                "$dynamicAnchor": "elements",
                additionalProperties: false,
                properties: %{a: true}
              }
            }
          },
          %JSV.Schema{"$ref": "extendible-dynamic-ref.json"}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "incorrect parent schema", x do
      data = %{"a" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "incorrect extended schema", x do
      data = %{"elements" => [%{"b" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "correct extended schema", x do
      data = %{"elements" => [%{"a" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$ref to $dynamicRef finds detached $dynamicAnchor" do
    setup do
      json_schema = %JSV.Schema{
        "$ref": "http://localhost:1234/draft2020-12/detached-dynamicref.json#/$defs/foo"
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

  describe "$dynamicRef points to a boolean schema" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{false: false, true: true},
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{
          false: %JSV.Schema{"$dynamicRef": "#/$defs/false"},
          true: %JSV.Schema{"$dynamicRef": "#/$defs/true"}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "follow $dynamicRef to a true schema", x do
      data = %{"true" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "follow $dynamicRef to a false schema", x do
      data = %{"false" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "$dynamicRef skips over intermediate resources - direct reference" do
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
        "$id": "https://test.json-schema.org/dynamic-ref-skips-intermediate-resource/main",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{"bar-item": %JSV.Schema{"$ref": "item"}}
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
