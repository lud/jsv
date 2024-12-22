# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.AdditionalPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/additionalProperties.json
  """

  describe "additionalProperties with schema" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: %{type: "boolean"},
        properties: %{foo: %{}, bar: %{}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no additional properties is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an additional valid property is valid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an additional invalid property is invalid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalProperties can exist by itself" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: %{type: "boolean"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "an additional valid property is valid", c do
      data = %{"foo" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an additional invalid property is invalid", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalProperties are allowed by default" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        properties: %{foo: %{}, bar: %{}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "additional properties are allowed", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalProperties does not look in applicators" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: %{type: "boolean"},
        allOf: [%{properties: %{foo: %{}}}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "properties defined in allOf are not examined", c do
      data = %{"bar" => true, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalProperties with null valued instance properties" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: %{type: "null"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null values", c do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalProperties with propertyNames" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: %{type: "number"},
        propertyNames: %{maxLength: 5}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Valid against both keywords", c do
      data = %{"apple" => 4}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "Valid against propertyNames, but not additionalProperties", c do
      data = %{"fig" => 2, "pear" => "available"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "dependentSchemas with additionalProperties" do
    setup do
      json_schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        additionalProperties: false,
        properties: %{foo2: %{}},
        dependentSchemas: %{foo: %{}, foo2: %{properties: %{bar: %{}}}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "additionalProperties doesn't consider dependentSchemas", c do
      data = %{"foo" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "additionalProperties can't see bar", c do
      data = %{"bar" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "additionalProperties can't see bar even when foo2 is present", c do
      data = %{"bar" => "", "foo2" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
