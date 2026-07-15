# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AtomKeys.Optional.BignumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/optional/bignum.json
  """

  describe "integer" do
    setup do
      json_schema = %JSV.Schema{type: "integer"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a bignum is an integer", x do
      data = 12_345_678_910_111_213_141_516_171_819_202_122_232_425_262_728_293_031
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a negative bignum is an integer", x do
      data = -12_345_678_910_111_213_141_516_171_819_202_122_232_425_262_728_293_031
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "number" do
    setup do
      json_schema = %JSV.Schema{type: "number"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a bignum is a number", x do
      data = 98_249_283_749_234_923_498_293_171_823_948_729_348_710_298_301_928_331
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a negative bignum is a number", x do
      data = -98_249_283_749_234_923_498_293_171_823_948_729_348_710_298_301_928_331
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "string" do
    setup do
      json_schema = %JSV.Schema{type: "string"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a bignum is not a string", x do
      data = 98_249_283_749_234_923_498_293_171_823_948_729_348_710_298_301_928_331
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "maximum integer comparison" do
    setup do
      json_schema = %JSV.Schema{maximum: 18_446_744_073_709_551_615}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "comparison works for high numbers", x do
      data = 18_446_744_073_709_551_600
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "float comparison with high precision" do
    setup do
      json_schema = %JSV.Schema{exclusiveMaximum: 9.727837981879871e26}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "comparison works for high numbers", x do
      data = 9.727837981879871e26
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "minimum integer comparison" do
    setup do
      json_schema = %JSV.Schema{minimum: -18_446_744_073_709_551_615}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "comparison works for very negative numbers", x do
      data = -18_446_744_073_709_551_600
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "float comparison with high precision on negative numbers" do
    setup do
      json_schema = %JSV.Schema{exclusiveMinimum: -9.727837981879871e26}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "comparison works for very negative numbers", x do
      data = -9.727837981879871e26
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
