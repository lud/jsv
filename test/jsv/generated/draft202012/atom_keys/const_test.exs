# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.ConstTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/const.json
  """

  describe "const validation" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: 2}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "same value is valid", x do
      data = 2
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "another value is invalid", x do
      data = 5
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "another type is invalid", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with object" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        const: %{baz: "bax", foo: "bar"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "same object is valid", x do
      data = %{"baz" => "bax", "foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "same object with different property order is valid", x do
      data = %{"baz" => "bax", "foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "another object is invalid", x do
      data = %{"foo" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "another type is invalid", x do
      data = [1, 2]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with array" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        const: [%{foo: "bar"}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "same array is valid", x do
      data = [%{"foo" => "bar"}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "another array item is invalid", x do
      data = [2]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "array with additional items is invalid", x do
      data = [1, 2, 3]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with null" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: nil}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "null is valid", x do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not null is invalid", x do
      data = 0
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with false does not match 0" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: false}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

  describe "const with true does not match 1" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: true}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

  describe "const with [false] does not match [0]" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: [false]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

  describe "const with [true] does not match [1]" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: [true]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

  describe "const with {\"a\": false} does not match {\"a\": 0}" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: %{a: false}}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "{\"a\": false} is valid", x do
      data = %{"a" => false}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "{\"a\": 0} is invalid", x do
      data = %{"a" => 0}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "{\"a\": 0.0} is invalid", x do
      data = %{"a" => 0.0}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with {\"a\": true} does not match {\"a\": 1}" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: %{a: true}}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "{\"a\": true} is valid", x do
      data = %{"a" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "{\"a\": 1} is invalid", x do
      data = %{"a" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "{\"a\": 1.0} is invalid", x do
      data = %{"a" => 1.0}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with 0 does not match other zero-like types" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: 0}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

    test "empty object is invalid", x do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty array is invalid", x do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty string is invalid", x do
      data = ""
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "const with 1 does not match true" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: 1}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

  describe "const with -2.0 matches integer and float types" do
    setup do
      json_schema = %{"$schema": "https://json-schema.org/draft/2020-12/schema", const: -2.0}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "integer -2 is valid", x do
      data = -2
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "integer 2 is invalid", x do
      data = 2
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float -2.0 is valid", x do
      data = -2.0
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float 2.0 is invalid", x do
      data = 2.0
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float -2.00001 is invalid", x do
      data = -2.00001
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "float and integers are equal up to 64-bit representation limits" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        const: 9_007_199_254_740_992
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "integer is valid", x do
      data = 9_007_199_254_740_992
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "integer minus one is invalid", x do
      data = 9_007_199_254_740_991
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float is valid", x do
      data = 9_007_199_254_740_992.0
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "float minus one is invalid", x do
      data = 9_007_199_254_740_991.0
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "nul characters in strings" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        const: <<104, 101, 108, 108, 111, 0, 116, 104, 101, 114, 101>>
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
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

  describe "characters with the same visual representation but different codepoint" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$comment": "U+03BC",
        const: "μ"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "character uses the same codepoint", x do
      data = "μ"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "character looks the same but uses a different codepoint", x do
      data = "µ"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "characters with the same visual representation, but different number of codepoints" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$comment": "U+00E4",
        const: "ä"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "character uses the same codepoint", x do
      data = "ä"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "character looks the same but uses combining marks", x do
      data = "ä"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
