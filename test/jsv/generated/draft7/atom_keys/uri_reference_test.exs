# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.AtomKeys.UriReferenceTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/optional/format/uri-reference.json
  """

  describe "validation of URI References" do
    setup do
      json_schema = %JSV.Schema{format: "uri-reference"}

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

    test "a valid URI", x do
      data = "http://foo.bar/?baz=qux#quux"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid protocol-relative URI Reference", x do
      data = "//foo.bar/?baz=qux#quux"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid relative URI Reference", x do
      data = "/abc"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid URI Reference", x do
      data = "\\\\WINDOWS\\fileshare"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid URI Reference", x do
      data = "abc"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid URI fragment", x do
      data = "#fragment"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid URI fragment", x do
      data = "#frag\\ment"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "unescaped non US-ASCII characters", x do
      data = "/foobar®.txt"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "invalid backslash character", x do
      data = "https://example.org/foobar\\.txt"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "URI with leading-zero IPv4 is structurally valid as a reg-name", x do
      data = "http://087.10.0.1/"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "URI with out-of-bounds IPv4 is structurally valid as a reg-name", x do
      data = "http://999.999.999.999/"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an empty URI reference", x do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a query-only reference", x do
      data = "?query=1"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a network-path reference with an empty authority", x do
      data = "//"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "an incomplete percent-encoding", x do
      data = "/%zz"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a double quote in a path", x do
      data = "/a\"b"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "square brackets outside an authority", x do
      data = "/[::1]"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a non-numeric port in a network-path reference", x do
      data = "//example.com:abc/p"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "more than one at-sign in the authority", x do
      data = "//a@b@example.com/"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a leading zero in the IPv4 part of an IPv6 literal", x do
      data = "//[::ffff:192.168.0.01]/p"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a colon in the first segment of a relative-path reference", x do
      data = "1:b"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a colon in the first segment preceded by a dot-segment", x do
      data = "./this:that"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
