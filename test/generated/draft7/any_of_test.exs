# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft7.AnyOfTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/anyOf.json
  """

  describe "anyOf:" do
    setup do
      json_schema = %{"anyOf" => [%{"type" => "integer"}, %{"minimum" => 2}]}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "first anyOf valid", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "second anyOf valid", c do
      data = 2.5
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both anyOf valid", c do
      data = 3
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "neither anyOf valid", c do
      data = 1.5
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "anyOf with base schema:" do
    setup do
      json_schema = %{"anyOf" => [%{"maxLength" => 2}, %{"minLength" => 4}], "type" => "string"}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "mismatch base schema", c do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "one anyOf valid", c do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both anyOf invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "anyOf with boolean schemas, all true:" do
    setup do
      json_schema = %{"anyOf" => [true, true]}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "anyOf with boolean schemas, some true:" do
    setup do
      json_schema = %{"anyOf" => [true, false]}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "anyOf with boolean schemas, all false:" do
    setup do
      json_schema = %{"anyOf" => [false, false]}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any value is invalid", c do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "anyOf complex types:" do
    setup do
      json_schema = %{
        "anyOf" => [
          %{"properties" => %{"bar" => %{"type" => "integer"}}, "required" => ["bar"]},
          %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "first anyOf valid (complex)", c do
      data = %{"bar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "second anyOf valid (complex)", c do
      data = %{"foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "both anyOf valid (complex)", c do
      data = %{"bar" => 2, "foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "neither anyOf valid (complex)", c do
      data = %{"bar" => "quux", "foo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "anyOf with one empty schema:" do
    setup do
      json_schema = %{"anyOf" => [%{"type" => "number"}, %{}]}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "string is valid", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "number is valid", c do
      data = 123
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested anyOf, to check validation semantics:" do
    setup do
      json_schema = %{"anyOf" => [%{"anyOf" => [%{"type" => "null"}]}]}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "null is valid", c do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "anything non-null is invalid", c do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
