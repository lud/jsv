# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AtomKeys.MaxPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/maxProperties.json
  """

  describe "maxProperties validation" do
    setup do
      json_schema = %JSV.Schema{maxProperties: 2}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "shorter is valid", x do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "exact length is valid", x do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "too long is invalid", x do
      data = %{"bar" => 2, "baz" => 3, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores arrays", x do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores strings", x do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores other non-objects", x do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "maxProperties validation with a decimal" do
    setup do
      json_schema = %JSV.Schema{maxProperties: 2.0}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "shorter is valid", x do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "too long is invalid", x do
      data = %{"bar" => 2, "baz" => 3, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "maxProperties = 0 means the object is empty" do
    setup do
      json_schema = %JSV.Schema{maxProperties: 0}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no properties is valid", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "one property is invalid", x do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
