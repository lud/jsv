# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DecimalValues.UniqueItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/uniqueItems.json
  """

  describe "uniqueItems validation" do
    setup do
      json_schema = %{"uniqueItems" => true}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "numbers are unique if mathematically unequal", x do
      data = [
        Decimal.new("1.0", JsonSchemaSuite.decimal_opts()),
        Decimal.new("1.00", JsonSchemaSuite.decimal_opts()),
        1
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "uniqueItems=false validation" do
    setup do
      json_schema = %{"uniqueItems" => false}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "numbers are unique if mathematically unequal", x do
      data = [
        Decimal.new("1.0", JsonSchemaSuite.decimal_opts()),
        Decimal.new("1.00", JsonSchemaSuite.decimal_opts()),
        1
      ]

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
