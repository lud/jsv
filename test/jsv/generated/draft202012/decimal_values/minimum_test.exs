# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.DecimalValues.MinimumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minimum.json
  """

  describe "minimum validation" do
    setup do
      json_schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minimum" => 1.1}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "above the minimum is valid", x do
      data = Decimal.new("2.6", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "boundary point is valid", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "below the minimum is invalid", x do
      data = Decimal.new("0.6", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "minimum validation with signed integer" do
    setup do
      json_schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minimum" => -2}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "boundary point with float is valid", x do
      data = Decimal.new("-2.0", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float below the minimum is invalid", x do
      data = Decimal.new("-2.0001", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
