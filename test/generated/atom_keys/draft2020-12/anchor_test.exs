# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.AnchorTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/anchor.json
  """

  describe "Location-independent identifier" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{A: %JSV.Schema{type: "integer", "$anchor": "foo"}},
        "$ref": "#foo",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "Location-independent identifier with absolute URI" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          A: %JSV.Schema{
            type: "integer",
            "$anchor": "foo",
            "$id": "http://localhost:1234/draft2020-12/bar"
          }
        },
        "$ref": "http://localhost:1234/draft2020-12/bar#foo",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "Location-independent identifier with base URI change in subschema" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          A: %JSV.Schema{
            "$defs": %{B: %JSV.Schema{type: "integer", "$anchor": "foo"}},
            "$id": "nested.json"
          }
        },
        "$id": "http://localhost:1234/draft2020-12/root",
        "$ref": "http://localhost:1234/draft2020-12/nested.json#foo",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mismatch", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "same $anchor with different base uri" do
    setup do
      json_schema = %JSV.Schema{
        "$defs": %{
          A: %JSV.Schema{
            "$id": "child1",
            allOf: [
              %JSV.Schema{type: "number", "$anchor": "my_anchor", "$id": "child2"},
              %JSV.Schema{type: "string", "$anchor": "my_anchor"}
            ]
          }
        },
        "$id": "http://localhost:1234/draft2020-12/foobar",
        "$ref": "child1#my_anchor",
        "$schema": "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "$ref resolves to /$defs/A/allOf/1", x do
      data = "a"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "$ref does not resolve to /$defs/A/allOf/0", x do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
