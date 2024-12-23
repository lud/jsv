# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.VocabularyTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/vocabulary.json
  """

  describe "schema that uses custom metaschema with with no validation vocabulary" do
    setup do
      json_schema = %JSV.Schema{
        "$id": "https://schema/using/no/validation",
        "$schema": "http://localhost:1234/draft2020-12/metaschema-no-validation.json",
        properties: %{badProperty: false, numberProperty: %JSV.Schema{minimum: 10}}
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "applicator vocabulary still works", x do
      data = %{"badProperty" => "this property should not exist"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "no validation: valid number", x do
      data = %{"numberProperty" => 20}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "no validation: invalid number, but it still validates", x do
      data = %{"numberProperty" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "ignore unrecognized optional vocabulary" do
    setup do
      json_schema = %JSV.Schema{
        type: "number",
        "$schema": "http://localhost:1234/draft2020-12/metaschema-optional-vocabulary.json"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "string value", x do
      data = "foobar"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "number value", x do
      data = 20
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
