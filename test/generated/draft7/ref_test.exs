# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.RefTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/ref.json
  """

  describe "root pointer ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "additionalProperties": false,
          "properties": {
            "foo": {
              "$ref": "#"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = %{"foo" => false}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "recursive match", c do
      data = %{"foo" => %{"foo" => false}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = %{"bar" => false}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "recursive mismatch", c do
      data = %{"foo" => %{"bar" => false}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "relative pointer ref to object:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "bar": {
              "$ref": "#/properties/foo"
            },
            "foo": {
              "type": "integer"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = %{"bar" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = %{"bar" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "relative pointer ref to array:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "items": [
            {
              "type": "integer"
            },
            {
              "$ref": "#/items/0"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match array", c do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch array", c do
      data = [1, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "escaped pointer ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "percent%field": {
              "type": "integer"
            },
            "slash/field": {
              "type": "integer"
            },
            "tilde~field": {
              "type": "integer"
            }
          },
          "properties": {
            "percent": {
              "$ref": "#/definitions/percent%25field"
            },
            "slash": {
              "$ref": "#/definitions/slash~1field"
            },
            "tilde": {
              "$ref": "#/definitions/tilde~0field"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "slash invalid", c do
      data = %{"slash" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "tilde invalid", c do
      data = %{"tilde" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "percent invalid", c do
      data = %{"percent" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "slash valid", c do
      data = %{"slash" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "tilde valid", c do
      data = %{"tilde" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "percent valid", c do
      data = %{"percent" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested refs:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "a": {
              "type": "integer"
            },
            "b": {
              "$ref": "#/definitions/a"
            },
            "c": {
              "$ref": "#/definitions/b"
            }
          },
          "allOf": [
            {
              "$ref": "#/definitions/c"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "nested ref valid", c do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "nested ref invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ref overrides any sibling keywords:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "reffed": {
              "type": "array"
            }
          },
          "properties": {
            "foo": {
              "$ref": "#/definitions/reffed",
              "maxItems": 2
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "ref valid", c do
      data = %{"foo" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ref valid, maxItems ignored", c do
      data = %{"foo" => [1, 2, 3]}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ref invalid", c do
      data = %{"foo" => "string"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$ref prevents a sibling $id from changing the base uri:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/sibling_id/base/",
          "definitions": {
            "base_foo": {
              "$id": "foo.json",
              "type": "number",
              "$comment": "this canonical uri is http://localhost:1234/sibling_id/base/foo.json"
            },
            "foo": {
              "$id": "http://localhost:1234/sibling_id/foo.json",
              "type": "string"
            }
          },
          "allOf": [
            {
              "$id": "http://localhost:1234/sibling_id/",
              "$comment": "$ref resolves to http://localhost:1234/sibling_id/base/foo.json, not http://localhost:1234/sibling_id/foo.json",
              "$ref": "foo.json"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "$ref resolves to /definitions/base_foo, data does not validate", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "$ref resolves to /definitions/base_foo, data validates", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "remote ref, containing refs itself:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://json-schema.org/draft-07/schema#"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "remote ref valid", c do
      data = %{"minLength" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "remote ref invalid", c do
      data = %{"minLength" => -1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "property named $ref that is not a reference:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "properties": {
            "$ref": {
              "type": "string"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "property named $ref valid", c do
      data = %{"$ref" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "property named $ref invalid", c do
      data = %{"$ref" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "property named $ref, containing an actual $ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "is-string": {
              "type": "string"
            }
          },
          "properties": {
            "$ref": {
              "$ref": "#/definitions/is-string"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "property named $ref valid", c do
      data = %{"$ref" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "property named $ref invalid", c do
      data = %{"$ref" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$ref to boolean schema true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "bool": true
          },
          "allOf": [
            {
              "$ref": "#/definitions/bool"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$ref to boolean schema false:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "bool": false
          },
          "allOf": [
            {
              "$ref": "#/definitions/bool"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Recursive references between schemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/tree",
          "definitions": {
            "node": {
              "$id": "http://localhost:1234/node",
              "type": "object",
              "description": "node",
              "properties": {
                "subtree": {
                  "$ref": "tree"
                },
                "value": {
                  "type": "number"
                }
              },
              "required": [
                "value"
              ]
            }
          },
          "type": "object",
          "description": "tree of nodes",
          "properties": {
            "meta": {
              "type": "string"
            },
            "nodes": {
              "type": "array",
              "items": {
                "$ref": "node"
              }
            }
          },
          "required": [
            "meta",
            "nodes"
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid tree", c do
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
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid tree", c do
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
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "refs with quote:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "foo\"bar": {
              "type": "number"
            }
          },
          "properties": {
            "foo\"bar": {
              "$ref": "#/definitions/foo%22bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with numbers is valid", c do
      data = %{"foo\"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object with strings is invalid", c do
      data = %{"foo\"bar" => "1"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Location-independent identifier:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "A": {
              "$id": "#foo",
              "type": "integer"
            }
          },
          "allOf": [
            {
              "$ref": "#foo"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Reference an anchor with a non-relative URI:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "https://example.com/schema-with-anchor",
          "definitions": {
            "A": {
              "$id": "#foo",
              "type": "integer"
            }
          },
          "allOf": [
            {
              "$ref": "https://example.com/schema-with-anchor#foo"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Location-independent identifier with base URI change in subschema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/root",
          "definitions": {
            "A": {
              "$id": "nested.json",
              "definitions": {
                "B": {
                  "$id": "#foo",
                  "type": "integer"
                }
              }
            }
          },
          "allOf": [
            {
              "$ref": "http://localhost:1234/nested.json#foo"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "naive replacement of $ref with its destination is not correct:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "a_string": {
              "type": "string"
            }
          },
          "enum": [
            {
              "$ref": "#/definitions/a_string"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "do not evaluate the $ref inside the enum, matching any string", c do
      data = "this is a string"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "do not evaluate the $ref inside the enum, definition exact match", c do
      data = %{"type" => "string"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "match the enum exactly", c do
      data = %{"$ref" => "#/definitions/a_string"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "refs with relative uris and defs:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://example.com/schema-relative-uri-defs1.json",
          "allOf": [
            {
              "$ref": "schema-relative-uri-defs2.json"
            }
          ],
          "properties": {
            "foo": {
              "$id": "schema-relative-uri-defs2.json",
              "definitions": {
                "inner": {
                  "properties": {
                    "bar": {
                      "type": "string"
                    }
                  }
                }
              },
              "allOf": [
                {
                  "$ref": "#/definitions/inner"
                }
              ]
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "invalid on inner field", c do
      data = %{"bar" => "a", "foo" => %{"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid on outer field", c do
      data = %{"bar" => 1, "foo" => %{"bar" => "a"}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid on both fields", c do
      data = %{"bar" => "a", "foo" => %{"bar" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "relative refs with absolute uris and defs:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://example.com/schema-refs-absolute-uris-defs1.json",
          "allOf": [
            {
              "$ref": "schema-refs-absolute-uris-defs2.json"
            }
          ],
          "properties": {
            "foo": {
              "$id": "http://example.com/schema-refs-absolute-uris-defs2.json",
              "definitions": {
                "inner": {
                  "properties": {
                    "bar": {
                      "type": "string"
                    }
                  }
                }
              },
              "allOf": [
                {
                  "$ref": "#/definitions/inner"
                }
              ]
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "invalid on inner field", c do
      data = %{"bar" => "a", "foo" => %{"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid on outer field", c do
      data = %{"bar" => 1, "foo" => %{"bar" => "a"}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid on both fields", c do
      data = %{"bar" => "a", "foo" => %{"bar" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$id must be resolved against nearest parent, not just immediate parent:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://example.com/a.json",
          "definitions": {
            "x": {
              "$id": "http://example.com/b/c.json",
              "not": {
                "definitions": {
                  "y": {
                    "$id": "d.json",
                    "type": "number"
                  }
                }
              }
            }
          },
          "allOf": [
            {
              "$ref": "http://example.com/b/d.json"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "non-number is invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "simple URN base URI with $ref via the URN:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed",
          "$comment": "URIs do not have to have HTTP(s) schemes",
          "minimum": 30,
          "properties": {
            "foo": {
              "$ref": "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid under the URN IDed schema", c do
      data = %{"foo" => 37}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid under the URN IDed schema", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "simple URN base URI with JSON pointer:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:uuid:deadbeef-1234-00ff-ff00-4321feebdaed",
          "definitions": {
            "bar": {
              "type": "string"
            }
          },
          "$comment": "URIs do not have to have HTTP(s) schemes",
          "properties": {
            "foo": {
              "$ref": "#/definitions/bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a non-string is invalid", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "URN base URI with NSS:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:example:1/406/47452/2",
          "definitions": {
            "bar": {
              "type": "string"
            }
          },
          "$comment": "RFC 8141 §2.2",
          "properties": {
            "foo": {
              "$ref": "#/definitions/bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a non-string is invalid", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "URN base URI with r-component:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:example:foo-bar-baz-qux?+CCResolve:cc=uk",
          "definitions": {
            "bar": {
              "type": "string"
            }
          },
          "$comment": "RFC 8141 §2.3.1",
          "properties": {
            "foo": {
              "$ref": "#/definitions/bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a non-string is invalid", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "URN base URI with q-component:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:example:weather?=op=map&lat=39.56&lon=-104.85&datetime=1969-07-21T02:56:15Z",
          "definitions": {
            "bar": {
              "type": "string"
            }
          },
          "$comment": "RFC 8141 §2.3.2",
          "properties": {
            "foo": {
              "$ref": "#/definitions/bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a non-string is invalid", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "URN base URI with URN and JSON pointer ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:uuid:deadbeef-1234-0000-0000-4321feebdaed",
          "definitions": {
            "bar": {
              "type": "string"
            }
          },
          "properties": {
            "foo": {
              "$ref": "urn:uuid:deadbeef-1234-0000-0000-4321feebdaed#/definitions/bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a non-string is invalid", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "URN base URI with URN and anchor ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed",
          "definitions": {
            "bar": {
              "$id": "#something",
              "type": "string"
            }
          },
          "properties": {
            "foo": {
              "$ref": "urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed#something"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a non-string is invalid", c do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ref to if:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "$ref": "http://example.com/ref/if"
            },
            {
              "if": {
                "$id": "http://example.com/ref/if",
                "type": "integer"
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an integer is valid", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ref to then:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "$ref": "http://example.com/ref/then"
            },
            {
              "then": {
                "$id": "http://example.com/ref/then",
                "type": "integer"
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an integer is valid", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ref to else:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "allOf": [
            {
              "$ref": "http://example.com/ref/else"
            },
            {
              "else": {
                "$id": "http://example.com/ref/else",
                "type": "integer"
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an integer is valid", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ref with absolute-path-reference:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://example.com/ref/absref.json",
          "definitions": {
            "a": {
              "$id": "http://example.com/ref/absref/foobar.json",
              "type": "number"
            },
            "b": {
              "$id": "http://example.com/absref/foobar.json",
              "type": "string"
            }
          },
          "allOf": [
            {
              "$ref": "/absref/foobar.json"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a string is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an integer is invalid", c do
      data = 12
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$id with file URI still resolves pointers - *nix:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "file:///folder/file.json",
          "definitions": {
            "foo": {
              "type": "number"
            }
          },
          "allOf": [
            {
              "$ref": "#/definitions/foo"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "non-number is invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$id with file URI still resolves pointers - windows:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "file:///c:/folder/file.json",
          "definitions": {
            "foo": {
              "type": "number"
            }
          },
          "allOf": [
            {
              "$ref": "#/definitions/foo"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "non-number is invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "empty tokens in $ref json-pointer:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "definitions": {
            "": {
              "definitions": {
                "": {
                  "type": "number"
                }
              }
            }
          },
          "allOf": [
            {
              "$ref": "#/definitions//definitions/"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "non-number is invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
