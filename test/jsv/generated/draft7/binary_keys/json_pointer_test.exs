# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.BinaryKeys.JsonPointerTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/optional/format/json-pointer.json
  """

  describe "validation of JSON-pointers (JSON String Representation)" do
    setup do
      json_schema = %{"format" => "json-pointer"}

      schema =
        JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema", formats: true)

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

    test "a valid JSON-pointer", x do
      data = "/foo/bar~0/baz~1/%a"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (~ not escaped)", x do
      data = "/foo/bar~"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer with empty segment", x do
      data = "/foo//bar"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer with the last empty segment", x do
      data = "/foo/bar/"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #1", x do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #2", x do
      data = "/foo"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #3", x do
      data = "/foo/0"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #4", x do
      data = "/"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #5", x do
      data = "/a~1b"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #6", x do
      data = "/c%d"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #7", x do
      data = "/e^f"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #8", x do
      data = "/g|h"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #9", x do
      data = "/i\\j"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #10", x do
      data = "/k\"l"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #11", x do
      data = "/ "
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer as stated in RFC 6901 #12", x do
      data = "/m~0n"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer used adding to the last array position", x do
      data = "/foo/-"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer (- used as object member name)", x do
      data = "/foo/-/bar"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer (multiple escaped characters)", x do
      data = "/~1~0~0~1~1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer (escaped with fraction part) #1", x do
      data = "/~1.1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer (escaped with fraction part) #2", x do
      data = "/~0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (URI Fragment Identifier) #1", x do
      data = "#"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (URI Fragment Identifier) #2", x do
      data = "#/"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (URI Fragment Identifier) #3", x do
      data = "#a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (some escaped, but not all) #1", x do
      data = "/~0~"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (some escaped, but not all) #2", x do
      data = "/~0/~"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (wrong escape character) #1", x do
      data = "/~2"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (wrong escape character) #2", x do
      data = "/~-1"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (multiple characters not escaped)", x do
      data = "/~~"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (isn't empty nor starts with /) #1", x do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (isn't empty nor starts with /) #2", x do
      data = "0"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "not a valid JSON-pointer (isn't empty nor starts with /) #3", x do
      data = "a/a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer (Unicode characters allowed by RFC 6901)", x do
      data = "/foo/bar/😎"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "valid JSON-pointer (control characters allowed after JSON unescaping)", x do
      data = <<47, 102, 111, 111, 0, 98, 97, 114, 10, 9, 98, 97, 122>>
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
