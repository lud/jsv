# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DecimalValues.OneOfTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/oneOf.json
  """

  describe "oneOf" do
    setup do
      json_schema = %{"oneOf" => [%{"type" => "integer"}, %{"minimum" => 2}]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "second oneOf valid", x do
      data = Decimal.new("2.5")
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "neither oneOf valid", x do
      data = Decimal.new("1.5")
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
