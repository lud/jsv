# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AnchorTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/anchor.json
  """

  describe "Location-independent identifier:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "A": {
              "type": "integer",
              "$anchor": "foo"
            }
          },
          "$ref": "#foo"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "Location-independent identifier with absolute URI:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "A": {
              "$id": "http://localhost:1234/draft2020-12/bar",
              "type": "integer",
              "$anchor": "foo"
            }
          },
          "$ref": "http://localhost:1234/draft2020-12/bar#foo"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "Location-independent identifier with base URI change in subschema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$id": "http://localhost:1234/draft2020-12/root",
          "$defs": {
            "A": {
              "$id": "nested.json",
              "$defs": {
                "B": {
                  "type": "integer",
                  "$anchor": "foo"
                }
              }
            }
          },
          "$ref": "http://localhost:1234/draft2020-12/nested.json#foo"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "same $anchor with different base uri:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$id": "http://localhost:1234/draft2020-12/foobar",
          "$defs": {
            "A": {
              "$id": "child1",
              "allOf": [
                {
                  "$id": "child2",
                  "type": "number",
                  "$anchor": "my_anchor"
                },
                {
                  "type": "string",
                  "$anchor": "my_anchor"
                }
              ]
            }
          },
          "$ref": "child1#my_anchor"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "$ref resolves to /$defs/A/allOf/1", c do
      data = "a"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "$ref does not resolve to /$defs/A/allOf/0", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
