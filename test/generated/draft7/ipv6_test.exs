# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft7.Ipv6Test do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/optional/format/ipv6.json
  """

  describe "validation of IPv6 addresses:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "format": "ipv6"
        }
        """)

      schema =
        JsonSchemaSuite.build_schema(json_schema, default_meta: "http://json-schema.org/draft-07/schema", formats: true)

      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all string formats ignore integers", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore floats", c do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore objects", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore booleans", c do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "all string formats ignore nulls", c do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "a valid IPv6 address", c do
      data = "::1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an IPv6 address with out-of-range values", c do
      data = "12345::"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "trailing 4 hex symbols is valid", c do
      data = "::abef"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "trailing 5 hex symbols is invalid", c do
      data = "::abcef"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an IPv6 address with too many components", c do
      data = "1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "an IPv6 address containing illegal characters", c do
      data = "::laptop"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "no digits is valid", c do
      data = "::"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "leading colons is valid", c do
      data = "::42:ff:1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "trailing colons is valid", c do
      data = "d6::"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "missing leading octet is invalid", c do
      data = ":2:3:4:5:6:7:8"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "missing trailing octet is invalid", c do
      data = "1:2:3:4:5:6:7:"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "missing leading octet with omitted octets later", c do
      data = ":2:3:4::8"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "single set of double colons in the middle is valid", c do
      data = "1:d6::42"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "two sets of double colons is invalid", c do
      data = "1::d6::42"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mixed format with the ipv4 section as decimal octets", c do
      data = "1::d6:192.168.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mixed format with double colons between the sections", c do
      data = "1:2::192.168.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mixed format with ipv4 section with octet out of range", c do
      data = "1::2:192.168.256.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mixed format with ipv4 section with a hex octet", c do
      data = "1::2:192.168.ff.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "mixed format with leading double colons (ipv4-mapped ipv6 address)", c do
      data = "::ffff:192.168.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "triple colons is invalid", c do
      data = "1:2:3:4:5:::8"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "8 octets", c do
      data = "1:2:3:4:5:6:7:8"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "insufficient octets without double colons", c do
      data = "1:2:3:4:5:6:7"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "no colons is invalid", c do
      data = "1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ipv4 is not ipv6", c do
      data = "127.0.0.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "ipv4 segment must have 4 octets", c do
      data = "1:2:3:4:1.2.3"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "leading whitespace is invalid", c do
      data = "  ::1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "trailing whitespace is invalid", c do
      data = "::1  "
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "netmask is not a part of ipv6 address", c do
      data = "fe80::/64"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "zone id is not a part of ipv6 address", c do
      data = "fe80::a%eth1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "a long valid ipv6", c do
      data = "1000:1000:1000:1000:1000:1000:255.255.255.255"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "a long invalid ipv6, below length limit, first", c do
      data = "100:100:100:100:100:100:255.255.255.255.255"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "a long invalid ipv6, below length limit, second", c do
      data = "100:100:100:100:100:100:100:255.255.255.255"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "invalid non-ASCII '৪' (a Bengali 4)", c do
      data = "1:2:3:4:5:6:7:৪"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end

    test "invalid non-ASCII '৪' (a Bengali 4) in the IPv4 portion", c do
      data = "1:2::192.16৪.0.1"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid, print_errors: false)
    end
  end
end
