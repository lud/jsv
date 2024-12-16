# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.MinPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minProperties.json
  """

  describe "minProperties validation:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "minProperties": 1
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "longer is valid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "exact length is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "too short is invalid", c do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores strings", c do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "minProperties validation with a decimal:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "minProperties": 1.0
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "longer is valid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "too short is invalid", c do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
