# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.ExclusiveMaximumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/exclusiveMaximum.json
  """

  describe "exclusiveMaximum validation:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "exclusiveMaximum": 3.0
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "below the exclusiveMaximum is valid", c do
      data = 2.2
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "boundary point is invalid", c do
      data = 3.0
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "above the exclusiveMaximum is invalid", c do
      data = 3.5
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-numbers", c do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
