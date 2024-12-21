# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.PatternPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/patternProperties.json
  """

  describe "patternProperties validates properties matching a regex:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "patternProperties": {
            "f.*o": {
              "type": "integer"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a single valid match is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "multiple valid matches is valid", c do
      data = %{"foo" => 1, "foooooo" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "a single invalid match is invalid", c do
      data = %{"foo" => "bar", "fooooo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "multiple invalid matches is invalid", c do
      data = %{"foo" => "bar", "foooooo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ignores arrays", c do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ignores strings", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "multiple simultaneous patternProperties are validated:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "patternProperties": {
            "a*": {
              "type": "integer"
            },
            "aaa*": {
              "maximum": 20
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "a single valid match is valid", c do
      data = %{"a" => 21}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "a simultaneous match is valid", c do
      data = %{"aaaa" => 18}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "multiple matches is valid", c do
      data = %{"a" => 21, "aaaa" => 18}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid due to one is invalid", c do
      data = %{"a" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid due to the other is invalid", c do
      data = %{"aaaa" => 31}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an invalid due to both is invalid", c do
      data = %{"aaa" => "foo", "aaaa" => 31}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "regexes are not anchored by default and are case sensitive:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "patternProperties": {
            "X_": {
              "type": "string"
            },
            "[0-9]{2,}": {
              "type": "boolean"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "non recognized members are ignored", c do
      data = %{"answer 1" => "42"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "recognized members are accounted for", c do
      data = %{"a31b" => nil}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "regexes are case sensitive", c do
      data = %{"a_x_3" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "regexes are case sensitive, 2", c do
      data = %{"a_X_3" => 3}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "patternProperties with boolean schemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "patternProperties": {
            "b.*": false,
            "f.*": true
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with property matching schema true is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "object with property matching schema false is invalid", c do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "object with both properties is invalid", c do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "object with a property matching both true and false is invalid", c do
      data = %{"foobar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "empty object is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "patternProperties with null valued instance properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "patternProperties": {
            "^.*bar$": {
              "type": "null"
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null values", c do
      data = %{"foobar" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
