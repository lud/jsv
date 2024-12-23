# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.DurationTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/duration.json
  """

  if JsonSchemaSuite.version_check("~> 1.17") do
    describe "validation of duration strings" do
      setup do
        json_schema = %JSV.Schema{
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          format: "duration"
        }

        schema =
          JsonSchemaSuite.build_schema(json_schema,
            default_meta: "https://json-schema.org/draft/2020-12/schema",
            formats: true
          )

        {:ok, json_schema: json_schema, schema: schema}
      end

      test "all string formats ignore integers", x do
        data = 12
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore floats", x do
        data = 13.7
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore objects", x do
        data = %{}
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore arrays", x do
        data = []
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore booleans", x do
        data = false
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "all string formats ignore nulls", x do
        data = nil
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "a valid duration string", x do
        data = "P4DT12H30M5S"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "an invalid duration string", x do
        data = "PT1D"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "no elements present", x do
        data = "P"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "no time elements present", x do
        data = "P1YT"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "no date or time elements present", x do
        data = "PT"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "elements out of order", x do
        data = "P2D1Y"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "missing time separator", x do
        data = "P1D2H"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "time element in the date position", x do
        data = "P2S"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "four years duration", x do
        data = "P4Y"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "zero time, in seconds", x do
        data = "PT0S"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "zero time, in days", x do
        data = "P0D"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "one month duration", x do
        data = "P1M"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "one minute duration", x do
        data = "PT1M"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "one and a half days, in hours", x do
        data = "PT36H"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "one and a half days, in days and hours", x do
        data = "P1DT12H"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "two weeks", x do
        data = "P2W"
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "invalid non-ASCII '২' (a Bengali 2)", x do
        data = "P২Y"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end

      test "element without unit", x do
        data = "P1"
        expected_valid = false
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end
    end
  end
end
