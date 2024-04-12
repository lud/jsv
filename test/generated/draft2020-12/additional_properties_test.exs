# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft202012.AdditionalPropertiesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/additionalProperties.json
  """

  describe "additionalProperties being false does not allow other properties:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => false,
        "patternProperties" => %{"^v" => %{}},
        "properties" => %{"bar" => %{}, "foo" => %{}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no additional properties is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional property is invalid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => "boom"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores strings", c do
      data = "foobarbaz"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "patternProperties are not additional properties", c do
      data = %{"foo" => 1, "vroom" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "non-ASCII pattern with additionalProperties:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => false,
        "patternProperties" => %{"^á" => %{}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "matching the pattern is valid", c do
      data = %{"ármányos" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "not matching the pattern is invalid", c do
      data = %{"élmény" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties with schema:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "boolean"},
        "properties" => %{"bar" => %{}, "foo" => %{}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no additional properties is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional valid property is valid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional invalid property is invalid", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties can exist by itself:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "boolean"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "an additional valid property is valid", c do
      data = %{"foo" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an additional invalid property is invalid", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties are allowed by default:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"bar" => %{}, "foo" => %{}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "additional properties are allowed", c do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties does not look in applicators:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "boolean"},
        "allOf" => [%{"properties" => %{"foo" => %{}}}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "properties defined in allOf are not examined", c do
      data = %{"bar" => true, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "additionalProperties with null valued instance properties:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "null"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null values", c do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
