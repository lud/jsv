defmodule Elixir.Moonwalk.Generated.Draft202012.OneOfTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "oneOf" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [%{"type" => "integer"}, %{"minimum" => 2}]
      }

      {:ok, schema: schema}
    end

    test "first oneOf valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "second oneOf valid", %{schema: schema} do
      data = 2.5
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both oneOf valid", %{schema: schema} do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "neither oneOf valid", %{schema: schema} do
      data = 1.5
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with base schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [%{"minLength" => 2}, %{"maxLength" => 4}],
        "type" => "string"
      }

      {:ok, schema: schema}
    end

    test "mismatch base schema", %{schema: schema} do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "one oneOf valid", %{schema: schema} do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both oneOf valid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, all true" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [true, true, true]
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, one true" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [true, false, false]
      }

      {:ok, schema: schema}
    end

    test "any value is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, more than one true" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [true, true, false]
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with boolean schemas, all false" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [false, false, false]
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf complex types" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [
          %{"properties" => %{"bar" => %{"type" => "integer"}}, "required" => ["bar"]},
          %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]}
        ]
      }

      {:ok, schema: schema}
    end

    test "first oneOf valid (complex)", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "second oneOf valid (complex)", %{schema: schema} do
      data = %{"foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both oneOf valid (complex)", %{schema: schema} do
      data = %{"bar" => 2, "foo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "neither oneOf valid (complex)", %{schema: schema} do
      data = %{"bar" => "quux", "foo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with empty schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [%{"type" => "number"}, %{}]
      }

      {:ok, schema: schema}
    end

    test "one valid - valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both valid - invalid", %{schema: schema} do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with required" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [%{"required" => ["foo", "bar"]}, %{"required" => ["foo", "baz"]}],
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "both invalid - invalid", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "first valid - valid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "second valid - valid", %{schema: schema} do
      data = %{"baz" => 3, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both valid - invalid", %{schema: schema} do
      data = %{"bar" => 2, "baz" => 3, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "oneOf with missing optional property" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [
          %{"properties" => %{"bar" => true, "baz" => true}, "required" => ["bar"]},
          %{"properties" => %{"foo" => true}, "required" => ["foo"]}
        ]
      }

      {:ok, schema: schema}
    end

    test "first oneOf valid", %{schema: schema} do
      data = %{"bar" => 8}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "second oneOf valid", %{schema: schema} do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both oneOf valid", %{schema: schema} do
      data = %{"bar" => 8, "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "neither oneOf valid", %{schema: schema} do
      data = %{"baz" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nested oneOf, to check validation semantics" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "oneOf" => [%{"oneOf" => [%{"type" => "null"}]}]
      }

      {:ok, schema: schema}
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "anything non-null is invalid", %{schema: schema} do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end