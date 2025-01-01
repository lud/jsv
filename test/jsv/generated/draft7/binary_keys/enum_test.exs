# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.BinaryKeys.EnumTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/enum.json
  """

  describe "simple enum validation" do
    setup do
      json_schema = %{"enum" => [1, 2, 3]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "one of the enum is valid", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "something else is invalid", x do
      data = 4
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "heterogeneous enum validation" do
    setup do
      json_schema = %{"enum" => [6, "foo", [], true, %{"foo" => 12}]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "one of the enum is valid", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "something else is invalid", x do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "objects are deep compared", x do
      data = %{"foo" => false}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid object matches", x do
      data = %{"foo" => 12}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "extra properties in object is invalid", x do
      data = %{"boo" => 42, "foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "heterogeneous enum-with-null validation" do
    setup do
      json_schema = %{"enum" => [6, nil]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "null is valid", x do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "number is valid", x do
      data = 6
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "something else is invalid", x do
      data = "test"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enums in properties" do
    setup do
      json_schema = %{
        "type" => "object",
        "properties" => %{
          "bar" => %{"enum" => ["bar"]},
          "foo" => %{"enum" => ["foo"]}
        },
        "required" => ["bar"]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "both properties are valid", x do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "wrong foo value", x do
      data = %{"bar" => "bar", "foo" => "foot"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "wrong bar value", x do
      data = %{"bar" => "bart", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "missing optional property is valid", x do
      data = %{"bar" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "missing required property is invalid", x do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "missing all properties is invalid", x do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with escaped characters" do
    setup do
      json_schema = %{"enum" => ["foo\nbar", "foo\rbar"]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "member 1 is valid", x do
      data = "foo\nbar"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "member 2 is valid", x do
      data = "foo\rbar"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "another string is invalid", x do
      data = "abc"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with false does not match 0" do
    setup do
      json_schema = %{"enum" => [false]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "false is valid", x do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "integer zero is invalid", x do
      data = 0
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float zero is invalid", x do
      data = 0.0
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with [false] does not match [0]" do
    setup do
      json_schema = %{"enum" => [[false]]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[false] is valid", x do
      data = [false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[0] is invalid", x do
      data = [0]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[0.0] is invalid", x do
      data = [0.0]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with true does not match 1" do
    setup do
      json_schema = %{"enum" => [true]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "true is valid", x do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "integer one is invalid", x do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float one is invalid", x do
      data = 1.0
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with [true] does not match [1]" do
    setup do
      json_schema = %{"enum" => [[true]]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[true] is valid", x do
      data = [true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[1] is invalid", x do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[1.0] is invalid", x do
      data = [1.0]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with 0 does not match false" do
    setup do
      json_schema = %{"enum" => [0]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "false is invalid", x do
      data = false
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "integer zero is valid", x do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float zero is valid", x do
      data = 0.0
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with [0] does not match [false]" do
    setup do
      json_schema = %{"enum" => [[0]]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[false] is invalid", x do
      data = [false]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[0] is valid", x do
      data = [0]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[0.0] is valid", x do
      data = [0.0]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with 1 does not match true" do
    setup do
      json_schema = %{"enum" => [1]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "true is invalid", x do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "integer one is valid", x do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float one is valid", x do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "enum with [1] does not match [true]" do
    setup do
      json_schema = %{"enum" => [[1]]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[true] is invalid", x do
      data = [true]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[1] is valid", x do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[1.0] is valid", x do
      data = [1.0]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nul characters in strings" do
    setup do
      json_schema = %{"enum" => [<<104, 101, 108, 108, 111, 0, 116, 104, 101, 114, 101>>]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match string with nul", x do
      data = <<104, 101, 108, 108, 111, 0, 116, 104, 101, 114, 101>>
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "do not match string lacking nul", x do
      data = "hellothere"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
