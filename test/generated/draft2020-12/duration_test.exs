# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.DurationTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/duration.json
  """

  if JsonSchemaSuite.version_check("~> 1.17") do
    describe "validation of duration strings:" do
      setup do
        json_schema =
          Jason.decode!(~S"""
          {
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "format": "duration"
          }
          """)

        schema =
          JsonSchemaSuite.build_schema(json_schema,
            default_meta: "https://json-schema.org/draft/2020-12/schema",
            formats: true
          )

        {:ok, json_schema: json_schema, schema: schema}
      end

      test "all string formats ignore integers", c do
        data = 12
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore floats", c do
        data = 13.7
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore objects", c do
        data = %{}
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore arrays", c do
        data = []
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore booleans", c do
        data = false
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore nulls", c do
        data = nil
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "a valid duration string", c do
        data = "P4DT12H30M5S"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "an invalid duration string", c do
        data = "PT1D"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "no elements present", c do
        data = "P"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "no time elements present", c do
        data = "P1YT"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "no date or time elements present", c do
        data = "PT"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "elements out of order", c do
        data = "P2D1Y"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "missing time separator", c do
        data = "P1D2H"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "time element in the date position", c do
        data = "P2S"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "four years duration", c do
        data = "P4Y"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "zero time, in seconds", c do
        data = "PT0S"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "zero time, in days", c do
        data = "P0D"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "one month duration", c do
        data = "P1M"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "one minute duration", c do
        data = "PT1M"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "one and a half days, in hours", c do
        data = "PT36H"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "one and a half days, in days and hours", c do
        data = "P1DT12H"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "two weeks", c do
        data = "P2W"
        expected_valid = true
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "invalid non-ASCII '২' (a Bengali 2)", c do
        data = "P২Y"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end

      test "element without unit", c do
        data = "P1"
        expected_valid = false
        JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
      end
    end
  end
end
