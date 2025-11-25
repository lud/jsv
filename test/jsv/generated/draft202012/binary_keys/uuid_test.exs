# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.UuidTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/uuid.json
  """

  describe "uuid format" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "uuid"
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

    test "all upper-case", x do
      data = "2EB8AA08-AA98-11EA-B4AA-73B441D16380"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all lower-case", x do
      data = "2eb8aa08-aa98-11ea-b4aa-73b441d16380"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "mixed case", x do
      data = "2eb8aa08-AA98-11ea-B4Aa-73B441D16380"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all zeroes is valid", x do
      data = "00000000-0000-0000-0000-000000000000"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "wrong length", x do
      data = "2eb8aa08-aa98-11ea-b4aa-73b441d1638"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "missing section", x do
      data = "2eb8aa08-aa98-11ea-73b441d16380"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "bad characters (not hex)", x do
      data = "2eb8aa08-aa98-11ea-b4ga-73b441d16380"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "no dashes", x do
      data = "2eb8aa08aa9811eab4aa73b441d16380"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "too few dashes", x do
      data = "2eb8aa08aa98-11ea-b4aa73b441d16380"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "too many dashes", x do
      data = "2eb8-aa08-aa98-11ea-b4aa73b44-1d16380"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "dashes in the wrong spot", x do
      data = "2eb8aa08aa9811eab4aa73b441d16380----"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "shifted dashes", x do
      data = "2eb8aa0-8aa98-11e-ab4aa7-3b441d16380"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid version 4", x do
      data = "98d80576-482e-427f-8434-7f86890ab222"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid version 5", x do
      data = "99c17cbb-656f-564a-940f-1a4568f03487"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "hypothetical version 6", x do
      data = "99c17cbb-656f-664a-940f-1a4568f03487"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "hypothetical version 15", x do
      data = "99c17cbb-656f-f64a-940f-1a4568f03487"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
