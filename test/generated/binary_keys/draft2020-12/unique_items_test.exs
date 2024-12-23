# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.UniqueItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/uniqueItems.json
  """

  describe "uniqueItems validation" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "uniqueItems" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "unique array of integers is valid", x do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of integers is invalid", x do
      data = [1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of more than two integers is invalid", x do
      data = [1, 2, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "numbers are unique if mathematically unequal", x do
      data = [1.0, 1.0, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "false is not equal to zero", x do
      data = [0, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "true is not equal to one", x do
      data = [1, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of strings is valid", x do
      data = ["foo", "bar", "baz"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of strings is invalid", x do
      data = ["foo", "bar", "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of objects is valid", x do
      data = [%{"foo" => "bar"}, %{"foo" => "baz"}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of objects is invalid", x do
      data = [%{"foo" => "bar"}, %{"foo" => "bar"}]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "property order of array of objects is ignored", x do
      data = [%{"bar" => "foo", "foo" => "bar"}, %{"bar" => "foo", "foo" => "bar"}]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of nested objects is valid", x do
      data = [
        %{"foo" => %{"bar" => %{"baz" => true}}},
        %{"foo" => %{"bar" => %{"baz" => false}}}
      ]

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of nested objects is invalid", x do
      data = [
        %{"foo" => %{"bar" => %{"baz" => true}}},
        %{"foo" => %{"bar" => %{"baz" => true}}}
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of arrays is valid", x do
      data = [["foo"], ["bar"]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of arrays is invalid", x do
      data = [["foo"], ["foo"]]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of more than two arrays is invalid", x do
      data = [["foo"], ["bar"], ["foo"]]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "1 and true are unique", x do
      data = [1, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "0 and false are unique", x do
      data = [0, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[1] and [true] are unique", x do
      data = [[1], [true]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[0] and [false] are unique", x do
      data = [[0], [false]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "nested [1] and [true] are unique", x do
      data = [[[1], "foo"], [[true], "foo"]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "nested [0] and [false] are unique", x do
      data = [[[0], "foo"], [[false], "foo"]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique heterogeneous types are valid", x do
      data = [%{}, [1], true, nil, 1, "{}"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique heterogeneous types are invalid", x do
      data = [%{}, [1], true, nil, %{}, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "different objects are unique", x do
      data = [%{"a" => 1, "b" => 2}, %{"a" => 2, "b" => 1}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "objects are non-unique despite key order", x do
      data = [%{"a" => 1, "b" => 2}, %{"a" => 1, "b" => 2}]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "{\"a\": false} and {\"a\": 0} are unique", x do
      data = [%{"a" => false}, %{"a" => 0}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "{\"a\": true} and {\"a\": 1} are unique", x do
      data = [%{"a" => true}, %{"a" => 1}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "uniqueItems with an array of items" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "boolean"}, %{"type" => "boolean"}],
        "uniqueItems" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[false, true] from items array is valid", x do
      data = [false, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, false] from items array is valid", x do
      data = [true, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[false, false] from items array is not valid", x do
      data = [false, false]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, true] from items array is not valid", x do
      data = [true, true]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array extended from [false, true] is valid", x do
      data = [false, true, "foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array extended from [true, false] is valid", x do
      data = [true, false, "foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array extended from [false, true] is not valid", x do
      data = [false, true, "foo", "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array extended from [true, false] is not valid", x do
      data = [true, false, "foo", "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "uniqueItems with an array of items and additionalItems=false" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => false,
        "prefixItems" => [%{"type" => "boolean"}, %{"type" => "boolean"}],
        "uniqueItems" => true
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[false, true] from items array is valid", x do
      data = [false, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, false] from items array is valid", x do
      data = [true, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[false, false] from items array is not valid", x do
      data = [false, false]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, true] from items array is not valid", x do
      data = [true, true]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "extra items are invalid even if unique", x do
      data = [false, true, nil]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "uniqueItems=false validation" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "uniqueItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "unique array of integers is valid", x do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of integers is valid", x do
      data = [1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "numbers are unique if mathematically unequal", x do
      data = [1.0, 1.0, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "false is not equal to zero", x do
      data = [0, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "true is not equal to one", x do
      data = [1, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of objects is valid", x do
      data = [%{"foo" => "bar"}, %{"foo" => "baz"}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of objects is valid", x do
      data = [%{"foo" => "bar"}, %{"foo" => "bar"}]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of nested objects is valid", x do
      data = [
        %{"foo" => %{"bar" => %{"baz" => true}}},
        %{"foo" => %{"bar" => %{"baz" => false}}}
      ]

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of nested objects is valid", x do
      data = [
        %{"foo" => %{"bar" => %{"baz" => true}}},
        %{"foo" => %{"bar" => %{"baz" => true}}}
      ]

      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array of arrays is valid", x do
      data = [["foo"], ["bar"]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array of arrays is valid", x do
      data = [["foo"], ["foo"]]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "1 and true are unique", x do
      data = [1, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "0 and false are unique", x do
      data = [0, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique heterogeneous types are valid", x do
      data = [%{}, [1], true, nil, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique heterogeneous types are valid", x do
      data = [%{}, [1], true, nil, %{}, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "uniqueItems=false with an array of items" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "boolean"}, %{"type" => "boolean"}],
        "uniqueItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[false, true] from items array is valid", x do
      data = [false, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, false] from items array is valid", x do
      data = [true, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[false, false] from items array is valid", x do
      data = [false, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, true] from items array is valid", x do
      data = [true, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array extended from [false, true] is valid", x do
      data = [false, true, "foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unique array extended from [true, false] is valid", x do
      data = [true, false, "foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array extended from [false, true] is valid", x do
      data = [false, true, "foo", "foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "non-unique array extended from [true, false] is valid", x do
      data = [true, false, "foo", "foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "uniqueItems=false with an array of items and additionalItems=false" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => false,
        "prefixItems" => [%{"type" => "boolean"}, %{"type" => "boolean"}],
        "uniqueItems" => false
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "[false, true] from items array is valid", x do
      data = [false, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, false] from items array is valid", x do
      data = [true, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[false, false] from items array is valid", x do
      data = [false, false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "[true, true] from items array is valid", x do
      data = [true, true]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "extra items are invalid even if unique", x do
      data = [false, true, nil]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
