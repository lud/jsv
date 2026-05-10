# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DecimalValues.ExclusiveMinimumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/exclusiveMinimum.json
  """

  describe "exclusiveMinimum validation" do
    setup do
      json_schema = %{"exclusiveMinimum" => 1.1}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "above the exclusiveMinimum is valid", x do
      data = Decimal.new("1.2", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "boundary point is invalid", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "below the exclusiveMinimum is invalid", x do
      data = Decimal.new("0.6", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
