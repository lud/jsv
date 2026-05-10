# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.DecimalValues.DurationTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/duration.json
  """

  if JsonSchemaSuite.version_check("~> 1.17") do
    describe "validation of duration strings" do
      setup do
        json_schema = %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "format" => "duration"
        }

        schema =
          JsonSchemaSuite.build_schema(json_schema,
            default_meta: "https://json-schema.org/draft/2020-12/schema",
            formats: true
          )

        {:ok, json_schema: json_schema, schema: schema}
      end

      test "all string formats ignore floats", x do
        data = Decimal.new("13.7", JsonSchemaSuite.decimal_opts())
        expected_valid = true
        JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
      end
    end
  end
end
