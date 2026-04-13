# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.BinaryKeys.IriTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/iri.json
  """

  describe "validation of IRIs" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "iri"
      }

      schema =
        JsonSchemaSuite.build_schema(json_schema,
          default_meta: "https://json-schema.org/draft/2020-12/schema",
          formats: true
        )

      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all string formats ignore integers", x do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore floats", x do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore objects", x do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore arrays", x do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore booleans", x do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore nulls", x do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid IRI with anchor tag", x do
      data = "http://ƒøø.ßår/?∂éœ=πîx#πîüx"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid IRI with anchor tag and parentheses", x do
      data = "http://ƒøø.com/blah_(wîkïpédiå)_blah#ßité-1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid IRI with URL-encoded stuff", x do
      data = "http://ƒøø.ßår/?q=Test%20URL-encoded%20stuff"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid IRI with many special characters", x do
      data = "http://-.~_!$&'()*+,;=:%40:80%2f::::::@example.com"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid IRI based on IPv6", x do
      data = "http://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an IPv6 address without enclosing brackets is invalid", x do
      data = "http://2001:0db8:85a3:0000:0000:8a2e:0370:7334"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid relative IRI Reference", x do
      data = "/abc"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid IRI", x do
      data = "\\\\WINDOWS\\filëßåré"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid IRI though valid IRI reference", x do
      data = "âππ"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
