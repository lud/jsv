# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.ExclusiveMaximumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/exclusiveMaximum.json
  """

  describe "exclusiveMaximum validation:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "exclusiveMaximum": 3.0
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "below the exclusiveMaximum is valid", c do
      data = 2.2
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "boundary point is invalid", c do
      data = 3.0
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "above the exclusiveMaximum is invalid", c do
      data = 3.5
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ignores non-numbers", c do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
