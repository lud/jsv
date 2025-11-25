# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.HostnameTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/hostname.json
  """

  describe "validation of host names" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        format: "hostname"
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

    test "a valid host name", x do
      data = "www.example.com"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "single label", x do
      data = "hostname"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "single label with digits", x do
      data = "h0stn4me"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "single label starting with digit", x do
      data = "1host"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "single label ending with digit", x do
      data = "hostnam3"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "empty string", x do
      data = ""
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "single dot", x do
      data = "."
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "leading dot", x do
      data = ".example"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "trailing dot", x do
      data = "example."
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "IDN label separator", x do
      data = "example．com"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "single label with hyphen", x do
      data = "host-name"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "starts with hyphen", x do
      data = "-hostname"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ends with hyphen", x do
      data = "hostname-"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "contains \"--\" in the 3rd and 4th position", x do
      data = "XN--aa---o47jg78q"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "contains underscore", x do
      data = "host_name"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "exceeds maximum overall length (256)", x do
      data =
        "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.com"

      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "maximum label length (63)", x do
      data = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.com"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "exceeds maximum label length (63)", x do
      data = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.com"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end

  describe "validation of A-label (punycode) host names" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        format: "hostname"
      }

      schema =
        JsonSchemaSuite.build_schema(json_schema,
          default_meta: "https://json-schema.org/draft/2020-12/schema",
          formats: true
        )

      {:ok, json_schema: json_schema, schema: schema}
    end

    test "invalid Punycode", x do
      data = "xn--X"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "a valid host name (example.test in Hangul)", x do
      data = "xn--9n2bp8q.xn--9t4b11yi5a"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "contains illegal char U+302E Hangul single dot tone mark", x do
      data = "xn--07jt112bpxg.xn--9t4b11yi5a"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Begins with a Spacing Combining Mark", x do
      data = "xn--hello-txk"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Begins with a Nonspacing Mark", x do
      data = "xn--hello-zed"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Begins with an Enclosing Mark", x do
      data = "xn--hello-6bf"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Exceptions that are PVALID, left-to-right chars", x do
      data = "xn--zca29lwxobi7a"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Exceptions that are PVALID, right-to-left chars", x do
      data = "xn--qmbc"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Exceptions that are DISALLOWED, right-to-left chars", x do
      data = "xn--chb89f"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Exceptions that are DISALLOWED, left-to-right chars", x do
      data = "xn--07jceefgh4c"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "MIDDLE DOT with no preceding 'l'", x do
      data = "xn--al-0ea"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "MIDDLE DOT with nothing preceding", x do
      data = "xn--l-fda"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "MIDDLE DOT with no following 'l'", x do
      data = "xn--la-0ea"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "MIDDLE DOT with nothing following", x do
      data = "xn--l-gda"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "MIDDLE DOT with surrounding 'l's", x do
      data = "xn--ll-0ea"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Greek KERAIA not followed by Greek", x do
      data = "xn--S-jib3p"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Greek KERAIA not followed by anything", x do
      data = "xn--wva3j"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Greek KERAIA followed by Greek", x do
      data = "xn--wva3je"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Hebrew GERESH not preceded by Hebrew", x do
      data = "xn--A-2hc5h"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Hebrew GERESH not preceded by anything", x do
      data = "xn--5db1e"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Hebrew GERESH preceded by Hebrew", x do
      data = "xn--4dbc5h"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Hebrew GERSHAYIM not preceded by Hebrew", x do
      data = "xn--A-2hc8h"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Hebrew GERSHAYIM not preceded by anything", x do
      data = "xn--5db3e"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Hebrew GERSHAYIM preceded by Hebrew", x do
      data = "xn--4dbc8h"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "KATAKANA MIDDLE DOT with no Hiragana, Katakana, or Han", x do
      data = "xn--defabc-k64e"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "KATAKANA MIDDLE DOT with no other characters", x do
      data = "xn--vek"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "KATAKANA MIDDLE DOT with Hiragana", x do
      data = "xn--k8j5u"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "KATAKANA MIDDLE DOT with Katakana", x do
      data = "xn--bck0j"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "KATAKANA MIDDLE DOT with Han", x do
      data = "xn--vek778f"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Arabic-Indic digits mixed with Extended Arabic-Indic digits", x do
      data = "xn--ngb6iyr"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Arabic-Indic digits not mixed with Extended Arabic-Indic digits", x do
      data = "xn--ngba1o"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "Extended Arabic-Indic digits not mixed with Arabic-Indic digits", x do
      data = "xn--0-gyc"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ZERO WIDTH JOINER not preceded by Virama", x do
      data = "xn--11b2er09f"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ZERO WIDTH JOINER not preceded by anything", x do
      data = "xn--02b508i"
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ZERO WIDTH JOINER preceded by Virama", x do
      data = "xn--11b2ezcw70k"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ZERO WIDTH NON-JOINER preceded by Virama", x do
      data = "xn--11b2ezcs70k"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "ZERO WIDTH NON-JOINER not preceded by Virama but matches regexp", x do
      data = "xn--ngba5hb2804a"
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
