# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft202012.Ipv4Test do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/ipv4.json
  """

  describe "validation of IP addresses:" do
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "ipv4"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, formats: true)
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all string formats ignore integers", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore floats", c do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore objects", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore booleans", c do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore nulls", c do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid IP address", c do
      data = "192.168.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an IP address with too many components", c do
      data = "127.0.0.0.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an IP address with out-of-range values", c do
      data = "256.256.256.256"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an IP address without 4 components", c do
      data = "127.0"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an IP address as an integer", c do
      data = "0x7f000001"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an IP address as an integer (decimal)", c do
      data = "2130706433"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leading zeroes, as they are treated as octals", c do
      data = "087.10.0.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "value without leading zero is valid", c do
      data = "87.10.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid non-ASCII '২' (a Bengali 2)", c do
      data = "1২7.0.0.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "netmask is not a part of ipv4 address", c do
      data = "192.168.1.0/24"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
