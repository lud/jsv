# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.DecimalValues.AnyOfTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/anyOf.json
  """

  describe "anyOf" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [%{"type" => "integer"}, %{"minimum" => 2}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "second anyOf valid", x do
      data = Decimal.new("2.5")
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "neither anyOf valid", x do
      data = Decimal.new("1.5")
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
