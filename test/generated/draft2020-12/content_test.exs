# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.ContentTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/content.json
  """

  describe "validation of string-encoded content based on media type:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "contentMediaType": "application/json"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a valid JSON document", c do
      data = "{\"foo\": \"bar\"}"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid JSON document; validates true", c do
      data = "{:}"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-strings", c do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "validation of binary string-encoding:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "contentEncoding": "base64"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a valid base64 string", c do
      data = "eyJmb28iOiAiYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid base64 string (% is not a valid character); validates true", c do
      data = "eyJmb28iOi%iYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-strings", c do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "validation of binary-encoded media type documents:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "contentEncoding": "base64",
          "contentMediaType": "application/json"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a valid base64-encoded JSON document", c do
      data = "eyJmb28iOiAiYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a validly-encoded invalid JSON document; validates true", c do
      data = "ezp9Cg=="
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid base64 string that is valid JSON; validates true", c do
      data = "{}"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-strings", c do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "validation of binary-encoded media type documents with schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "contentEncoding": "base64",
          "contentMediaType": "application/json",
          "contentSchema": {
            "type": "object",
            "properties": {
              "foo": {
                "type": "string"
              }
            },
            "required": [
              "foo"
            ]
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a valid base64-encoded JSON document", c do
      data = "eyJmb28iOiAiYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "another valid base64-encoded JSON document", c do
      data = "eyJib28iOiAyMCwgImZvbyI6ICJiYXoifQ=="
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid base64-encoded JSON document; validates true", c do
      data = "eyJib28iOiAyMH0="
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an empty object as a base64-encoded JSON document; validates true", c do
      data = "e30="
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an empty array as a base64-encoded JSON document", c do
      data = "W10="
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a validly-encoded invalid JSON document; validates true", c do
      data = "ezp9Cg=="
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid base64 string that is valid JSON; validates true", c do
      data = "{}"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-strings", c do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
