# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DefinitionsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/definitions.json
  """

  describe "validate definition against metaschema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$ref": "http://json-schema.org/draft-07/schema#"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid definition schema", c do
      data = %{"definitions" => %{"foo" => %{"type" => "integer"}}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "invalid definition schema", c do
      data = %{"definitions" => %{"foo" => %{"type" => 1}}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
