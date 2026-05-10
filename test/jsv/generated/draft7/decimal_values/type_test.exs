# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.DecimalValues.TypeTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/type.json
  """

  describe "integer type matches integers" do
    setup do
      json_schema = %{"type" => "integer"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float with zero fractional part is an integer", x do
      data = Decimal.new("1.0", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a float is not an integer", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "number type matches numbers" do
    setup do
      json_schema = %{"type" => "number"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float with zero fractional part is a number (and an integer)", x do
      data = Decimal.new("1.0", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a float is a number", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "string type matches strings" do
    setup do
      json_schema = %{"type" => "string"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float is not a string", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "object type matches objects" do
    setup do
      json_schema = %{"type" => "object"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float is not an object", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "array type matches arrays" do
    setup do
      json_schema = %{"type" => "array"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float is not an array", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "boolean type matches booleans" do
    setup do
      json_schema = %{"type" => "boolean"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float is not a boolean", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "null type matches only the null object" do
    setup do
      json_schema = %{"type" => "null"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float is not null", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "multiple types can be specified in an array" do
    setup do
      json_schema = %{"type" => ["integer", "string"]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a float is invalid", x do
      data = Decimal.new("1.1", JsonSchemaSuite.decimal_opts())
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
