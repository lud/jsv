# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AtomKeys.AdditionalItemsTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/additionalItems.json
  """

  describe "additionalItems as schema" do
    setup do
      json_schema = %JSV.Schema{
        additionalItems: %JSV.Schema{type: "integer"},
        items: [%JSV.Schema{}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "additional items match schema", x do
      data = [nil, 2, 3, 4]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "additional items do not match schema", x do
      data = [nil, 2, 3, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "when items is schema, additionalItems does nothing" do
    setup do
      json_schema = %JSV.Schema{
        additionalItems: %JSV.Schema{type: "string"},
        items: %JSV.Schema{type: "integer"}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid with a array of type integers", x do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid with a array of mixed types", x do
      data = [1, "2", "3"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "when items is schema, boolean additionalItems does nothing" do
    setup do
      json_schema = %JSV.Schema{additionalItems: false, items: %JSV.Schema{}}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all items match schema", x do
      data = [1, 2, 3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "array of items with no additionalItems permitted" do
    setup do
      json_schema = %JSV.Schema{
        additionalItems: false,
        items: [%JSV.Schema{}, %JSV.Schema{}, %JSV.Schema{}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "empty array", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "fewer number of items present (1)", x do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "fewer number of items present (2)", x do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "equal number of items present", x do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "additional items are not permitted", x do
      data = [1, 2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems as false without items" do
    setup do
      json_schema = %JSV.Schema{additionalItems: false}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "items defaults to empty schema so everything is valid", x do
      data = [1, 2, 3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ignores non-arrays", x do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems are allowed by default" do
    setup do
      json_schema = %JSV.Schema{items: [%JSV.Schema{type: "integer"}]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "only the first item is validated", x do
      data = [1, "foo", false]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems does not look in applicators, invalid case" do
    setup do
      json_schema = %JSV.Schema{
        additionalItems: %JSV.Schema{type: "boolean"},
        allOf: [
          %JSV.Schema{
            items: [%JSV.Schema{type: "integer"}, %JSV.Schema{type: "string"}]
          }
        ],
        items: [%JSV.Schema{type: "integer"}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "items defined in allOf are not examined", x do
      data = [1, "hello"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "items validation adjusts the starting index for additionalItems" do
    setup do
      json_schema = %JSV.Schema{
        additionalItems: %JSV.Schema{type: "integer"},
        items: [%JSV.Schema{type: "string"}]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid items", x do
      data = ["x", 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "wrong type of second item", x do
      data = ["x", "y"]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems with heterogeneous array" do
    setup do
      json_schema = %JSV.Schema{additionalItems: false, items: [%JSV.Schema{}]}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "heterogeneous invalid instance", x do
      data = ["foo", "bar", 37]
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid instance", x do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "additionalItems with null instance elements" do
    setup do
      json_schema = %JSV.Schema{additionalItems: %JSV.Schema{type: "null"}}
      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null elements", x do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
