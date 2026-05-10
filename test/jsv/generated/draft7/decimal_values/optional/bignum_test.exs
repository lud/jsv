# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DecimalValues.Optional.BignumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/optional/bignum.json
  """

  describe "float comparison with high precision" do
    setup do
      json_schema = %{"exclusiveMaximum" => 9.727837981879871e26}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "comparison works for high numbers", x do
      data = Decimal.new("972783798187987123879878123.188781371", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "float comparison with high precision on negative numbers" do
    setup do
      json_schema = %{"exclusiveMinimum" => -9.727837981879871e26}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "comparison works for very negative numbers", x do
      data = Decimal.new("-972783798187987123879878123.188781371", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
