# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.RefRemoteTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/refRemote.json
  """

  describe "remote ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://localhost:1234/integer.json"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "remote ref valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "remote ref invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "fragment within remote ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://localhost:1234/draft7/subSchemas.json#/definitions/integer"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "remote fragment valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "remote fragment invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ref within remote ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://localhost:1234/draft7/subSchemas.json#/definitions/refToInteger"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "ref within ref valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ref within ref invalid", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "base URI change:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/",
          "items": {
            "$id": "baseUriChange/",
            "items": {
              "$ref": "folderInteger.json"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "base URI change ref valid", c do
      data = [[1]]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "base URI change ref invalid", c do
      data = [["a"]]
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "base URI change - change folder:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/scope_change_defs1.json",
          "definitions": {
            "baz": {
              "$id": "baseUriChangeFolder/",
              "type": "array",
              "items": {
                "$ref": "folderInteger.json"
              }
            }
          },
          "type": "object",
          "properties": {
            "list": {
              "$ref": "#/definitions/baz"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = %{"list" => [1]}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string is invalid", c do
      data = %{"list" => ["a"]}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "base URI change - change folder in subschema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/scope_change_defs2.json",
          "definitions": {
            "baz": {
              "$id": "baseUriChangeFolderInSubschema/",
              "definitions": {
                "bar": {
                  "type": "array",
                  "items": {
                    "$ref": "folderInteger.json"
                  }
                }
              }
            }
          },
          "type": "object",
          "properties": {
            "list": {
              "$ref": "#/definitions/baz/definitions/bar"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is valid", c do
      data = %{"list" => [1]}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string is invalid", c do
      data = %{"list" => ["a"]}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "root ref in remote ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/object",
          "type": "object",
          "properties": {
            "name": {
              "$ref": "draft7/name.json#/definitions/orNull"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "string is valid", c do
      data = %{"name" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "null is valid", c do
      data = %{"name" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object is invalid", c do
      data = %{"name" => %{"name" => nil}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "remote ref with ref to definitions:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/schema-remote-ref-ref-defs1.json",
          "allOf": [
            {
              "$ref": "draft7/ref-and-definitions.json"
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "invalid", c do
      data = %{"bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "valid", c do
      data = %{"bar" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Location-independent identifier in remote ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://localhost:1234/draft7/locationIndependentIdentifier.json#/definitions/refToInteger"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "integer is valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "retrieved nested refs resolve relative to their URI not $id:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$id": "http://localhost:1234/some-id",
          "properties": {
            "name": {
              "$ref": "nested/foo-ref-string.json"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "number is invalid", c do
      data = %{"name" => %{"foo" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string is valid", c do
      data = %{"name" => %{"foo" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "$ref to $ref finds location-independent $id:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://localhost:1234/draft7/detached-ref.json#/definitions/foo"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
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
