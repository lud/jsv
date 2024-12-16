defmodule JSV.FormatValidationTest do
  alias JSV
  use ExUnit.Case, async: true

  defp build_schema(json_schema, opts \\ []) do
    JSV.build(json_schema, [resolver: JSV.Test.TestResolver] ++ opts)
  end

  defp raw_for(format) do
    %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "format" => format
    }
  end

  defp format_schema(format) do
    raw = raw_for(format)
    assert {:ok, schema} = build_schema(raw, formats: true)
    schema
  end

  @bad_ipv4 "not an ipv4"

  describe "build-time opt-in format validation" do
    # The default meta schema uses format-annotation and thus does not validate
    # formats
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "ipv4"
      }

      {:ok, json_schema: json_schema}
    end

    test "default to no validation", ctx do
      assert {:ok, schema} = build_schema(ctx.json_schema)
      assert {:ok, @bad_ipv4} = JSV.validate(schema, @bad_ipv4)
    end

    test "validation can be enabled in build", ctx do
      # Note that passing `true` is the same as passing a list with a single
      # item, the default formats module
      assert {:ok, schema} = build_schema(ctx.json_schema, formats: true)
      assert {:error, {:schema_validation, [_]}} = JSV.validate(schema, @bad_ipv4)
    end
  end

  describe "build-time opt-out format validation" do
    # We use a custom schema that uses format-assertion by default
    setup do
      json_schema =
        %{
          "$schema" => "http://localhost:1234/draft2020-12/format-assertion-true.json",
          "format" => "ipv4"
        }

      {:ok, json_schema: json_schema}
    end

    test "default to no validation", ctx do
      assert {:ok, schema} = build_schema(ctx.json_schema)
      assert {:error, {:schema_validation, [_]}} = JSV.validate(schema, @bad_ipv4)
    end

    test "validation can be enabled in build", ctx do
      assert {:ok, schema} = build_schema(ctx.json_schema, formats: false)
      assert {:ok, @bad_ipv4} = JSV.validate(schema, @bad_ipv4)
    end
  end

  describe "custom formats module" do
    defmodule CustomFormat do
      @behaviour JSV.FormatValidator

      def supported_formats do
        ["beam-language", "date"]
      end

      def validate_cast("beam-language", data) do
        if data in ["Elixir", "Erlang", "Gleam", "LFE"] do
          {:ok, data}
        else
          {:error, :non_beam_language}
        end
      end

      def validate_cast("date", anything) do
        {:ok, anything}
      end
    end

    test "passing a custom module" do
      # This will only support our formats
      formats = [CustomFormat]

      # We can validate the supported formats
      assert {:ok, schema} = build_schema(raw_for("beam-language"), formats: formats)
      assert {:ok, "LFE"} = JSV.validate(schema, "LFE")

      # but it does not support ipv4 format
      assert {:error, {:unsupported_format, "ipv4"}} = build_schema(raw_for("ipv4"), formats: formats)
    end

    test "adding a custom module over default one" do
      # Now if we ADD the module to the default we can support both formats
      formats = [CustomFormat | JSV.default_format_validator_modules()]

      # We can validate the supported formats
      assert {:ok, schema} = build_schema(raw_for("beam-language"), formats: formats)
      assert {:ok, "LFE"} = JSV.validate(schema, "LFE")

      # and it does support ipv4 format
      assert {:ok, schema} = build_schema(raw_for("ipv4"), formats: formats)
      assert {:ok, "127.0.0.1"} = JSV.validate(schema, "127.0.0.1")

      # and we were able to override default implementations
      assert {:ok, schema} = build_schema(raw_for("date"), formats: formats)
      assert {:ok, "a long time ago"} = JSV.validate(schema, "a long time ago")
    end
  end

  IO.warn("@todo test output of error messages")

  describe "common formats -" do
    defp run_cases(format, valids, invalids) do
      schema = format_schema(format)

      Enum.each(valids, fn value ->
        case JSV.validate(schema, value) do
          {:ok, ^value} ->
            :ok

          {:error, _} ->
            flunk("""
            Expected value #{inspect(value)} to be valid against format #{inspect(format)}.
            """)
        end
      end)

      Enum.each(invalids, fn value ->
        case JSV.validate(schema, value) do
          {:ok, ^value} ->
            flunk("""
            Expected value #{inspect(value)} to not be valid against format #{inspect(format)}.
            """)

          {:error, _} ->
            :ok
        end
      end)
    end

    test "date-time" do
      run_cases(
        "date-time",
        [
          # Complete date-time in UTC
          "2024-12-14T23:10:00Z",
          # Date-time with timezone offset
          "2024-12-14T18:10:00-05:00",
          # Date-time with positive timezone offset
          "2024-12-14T23:10:00+01:00",
          # Date-time including milliseconds in UTC
          "2024-12-14T23:10:00.500Z",
          # Date-time with comma as decimal separator for milliseconds in UTC
          "2024-12-14T23:10:00,500Z",

          # Incorrect milliseconds precision (too many digits)
          # But Elixir parser will accept it
          "2024-12-14T23:10:00.5000Z"
        ],
        [
          # Invalid month (13)
          "2024-13-14T23:10:00Z",
          # Invalid day (32)
          "2024-12-32T23:10:00Z",
          # Invalid hour (24)
          "2024-12-14T24:00:00Z",
          # Invalid minute (60)
          "2024-12-14T23:60:00Z",
          # Invalid second (60)
          "2024-12-14T23:10:60Z",
          # Missing timezone designator or offset
          "2024-12-14T23:10:00",
          # Invalid timezone offset hour (25)
          "2024-12-14T23:10:00+25:00",
          # Invalid timezone offset minute (61)
          "2024-12-14T23:10:00+01:61",
          # Space instead of 'T' between date and time
          "2024-12-14 23:10:00Z"
        ]
      )
    end

    test "time" do
      run_cases(
        "time",
        # Valid time strings
        [
          # Complete time with hours, minutes, seconds
          "23:10:00",
          # Time with UTC designator
          "23:10:00Z",
          # Time with positive timezone offset
          "23:10:00+01:00",
          # Time with negative timezone offset
          "23:10:00-05:00",
          # Time including milliseconds
          "23:10:00.500",
          # Time with comma as decimal separator for milliseconds
          "23:10:00,500",
          # Incorrect milliseconds precision (too many digits) but Elixir parser will accept it
          "23:10:00.5000",
          # Incomplete timezone offset, Elixir accepts it because it discards the time offset in Time
          "23:10:00+01"
        ],

        # Invalid time strings
        [
          # Invalid hour (24)
          "24:00:00",
          # Invalid minute (60)
          "23:60:00",
          # Invalid second (60)
          "23:10:60",
          # Missing seconds
          "23:10",
          # Invalid timezone offset hour (25)
          "23:10:00+25:00",
          # Invalid timezone offset minute (61)
          "23:10:00+01:61",
          # Space before UTC designator
          "23:10:00 Z"
        ]
      )
    end

    test "date" do
      run_cases(
        "date",
        # Valid date strings
        [
          # Complete date with year, month, day
          "2024-12-14",
          # Leap year date
          "2024-02-29"
        ],

        # Invalid date strings
        [
          # Year and month only, unsupported by Elixir
          "2024-12",
          # Year only, unsupported by Elixir
          "2024",
          # Week date, unsupported by Elixir
          "2024-W50",
          # Week date with specific day, unsupported by Elixir
          "2024-W50-6",

          # Generic
          # Invalid month (13)
          "2024-13-14",
          # Invalid day (32)
          "2024-12-32",
          # Non-existent date in February
          "2024-02-30",
          # Invalid month (00)
          "2024-00-10",
          # Invalid day (00)
          "2024-12-00",
          # Incorrect separator (slash instead of dash)
          "2024/12/14",
          # Invalid week number (55)
          "2024-W55",
          # Invalid day in week (8)
          "2024-W50-8",
          # Invalid format with trailing 'T'
          "2024-12-14T",
          # Invalid format with trailing 'Z'
          "2024-12-14Z"
        ]
      )
    end

    test "duration" do
      run_cases(
        "duration",
        # Valid duration strings
        [
          # 1 year, 2 months, 10 days, 2 hours, 30 minutes
          "P1Y2M10DT2H30M",
          # 3 years
          "P3Y",
          # 4 weeks
          "P4W",
          # 1 year, 2 months
          "P1Y2M",
          # 5 hours, 30 minutes
          "PT5H30M",
          # 10 seconds
          "PT10S",
          # Mixed with fractional seconds
          "P1Y2M3DT4H5M6.7S",

          # Negative duration not allowed, but Elixir accepts it
          "P-1Y",
          # Invalid minute value (60), but Elixir accepts infinite amounts
          "P1Y2M3DT4H60M",
          # Invalid hour value (24), same
          "P1Y2M3DT24H",
          # Excessive precision is ok in Elixir
          "PT10.0000000000001S"
        ],

        # Invalid duration strings
        [
          # Half a year, unsupported by elixir
          "P0.5Y",
          # Missing duration components
          "P",
          # Missing time components
          "PT",

          # Time components must be prefixed with 'T'
          "P1Y2M3D4H",
          # Fractional days not directly allowed (should be PT84H)
          "P1Y2M3.5D",

          # Missing 'P' at the start
          "1Y2M3D"
        ]
      )
    end

    # idn-email is not supported
    test "email" do
      from_block = fn block ->
        block
        |> String.trim()
        |> String.split("\n")
      end

      valid_emails =
        from_block.(~S"""
        email@example.com
        firstname.lastname@example.com
        email@subdomain.example.com
        firstname+lastname@example.com
        email@123.123.123.123
        "email"@example.com
        1234567890@example.com
        email@example-one.com
        _______@example.com
        email@example.name
        email@example.museum
        email@example.co.jp
        firstname-lastname@example.com
        """)

      invalid_emails =
        from_block.(~S"""
        plainaddress
        #@%^%#$@#$@#.com
        @example.com
        Joe Smith <email@example.com>
        email.example.com
        email@example@example.com
        .email@example.com
        email.@example.com
        email..email@example.com
        あいうえお@example.com
        email@example.com (Joe Smith)
        email@-example.com
        email@example..com
        Abc..123@example.com
        ”(),:;<>[\]@example.com
        just”not”right@example.com
        this\ is"really"not\allowed@example.com
        """)

      run_cases("email", valid_emails, invalid_emails)
    end

    # idn-hostname is not supported
    test "hostname" do
      run_cases(
        "hostname",
        # valids
        [
          "g.co",
          "google.com",
          "pref.stuff-info.com",
          "pref.stuff.com",
          "stuff-info.com",
          "stuff.com.au",
          "stuff.x.x.co",
          "stuff.x.x.c",
          "stuff123.com",
          "stuff.42",
          "www.google.com"
        ],
        # invalids
        [
          "-stuff.com",
          ".com",
          "pref.stuff-.com",
          "stuff-.com",
          "stuff,com",
          "stuff.com/users",
          "sub.-stuff.com"
        ]
      )
    end

    test "ipv4" do
      run_cases(
        "ipv4",
        # Valid IPv4 addresses
        [
          # Standard IPv4 address
          "192.168.1.1",
          # IPv4 address with zero in octets
          "10.0.0.0",
          # Maximum value for an IPv4 address
          "255.255.255.255",
          # Private network address
          "172.16.254.1",
          # Address representing "any" host
          "0.0.0.0",
          # Loopback address
          "127.0.0.1"
        ],

        # Invalid IPv4 addresses
        [
          # Values above 255 are invalid
          "256.256.256.256",
          # Missing one octet
          "192.168.1",
          # Extra octet
          "192.168.1.1.1",
          # Leading zero in octet
          "192.168.01.1",
          # Negative value in octet
          "192.168.1.-1",
          # CIDR notation not valid as a plain address
          "192.168.1.1/24",
          # Single octet above valid range
          "192.168.1.256",
          # Non-numeric characters
          "abc.def.ghi.jkl",
          # Trailing space
          "192.168.1.1 ",
          # Leading dot
          ".192.168.1.1"
        ]
      )
    end

    test "ipv6" do
      run_cases(
        "ipv6",
        # Valid IPv6 addresses
        [
          # Standard full IPv6 address
          "2001:0db8:85a3:0000:0000:8a2e:0370:7334",
          # Compressed zeros
          "2001:db8:85a3::8a2e:370:7334",
          # Loopback address
          "::1",
          # Link-local address
          "fe80::",
          # IPv4-mapped IPv6 address
          "::ffff:192.168.1.1",
          # Compressed zeros with trailing components
          "2001:db8::2:1",
          # Loopback in expanded form
          "0:0:0:0:0:0:0:1",
          # Mixed notation
          "2001:0db8:0000:0042:0000:8a2e:0370:7334"
        ],

        # Invalid IPv6 addresses
        [
          # Excessive value in segment
          "2001:db8:85a3:0:0:8a2e:37023:7334",
          # Double "::"
          "2001:db8:85a3::8a2e::7334",
          # Invalid character 'g'
          "2001:dg8:85a3::8a2e:370:7334",
          # Too many segments
          "2001:db8:85a3:0000:0000:8a2e:0370:7334:1234",
          # Too few segments
          "2001:db8:85a3",
          # Multiple compressed sections
          "1::2::3",
          # Leading colon without compression
          ":2001:db8::1",
          # Trailing colon without compression
          "2001:db8::1:",
          # More than one "::"
          "2001:0db8::85a3::8a2e:0370:7334",
          # Mixing IPv4 in non-mapped address
          "2001:db8:85a3::8a2e:370:7334:192.168.1.1"
        ]
      )
    end

    test "uuid" do
      run_cases(
        "uuid",
        # Valid UUIDs
        [
          # Standard UUID version 4
          "123e4567-e89b-12d3-a456-426614174000",
          # UUID version 1
          "550e8400-e29b-11d4-a716-446655440000",
          # Nil UUID
          "00000000-0000-0000-0000-000000000000",
          # Random UUID
          "f47ac10b-58cc-4372-a567-0e02b2c3d479",
          # UUID version 1 with timestamp
          "9a2a704c-1c7d-11ec-b52c-0242ac130003"
        ],

        # Invalid UUIDs
        [
          # Missing one character
          "123e4567-e89b-12d3-a456-42661417400",
          # One extra character
          "123e4567-e89b-12d3-a456-4266141740000",
          # Invalid character 'g'
          "g47ac10b-58cc-4372-a567-0e02b2c3d479",
          # Missing hyphens
          "123e4567e89b12d3a456426614174000",
          # Invalid character 'z'
          "123e4567-e89b-12d3-a456-42661417400z",
          # Extra hyphen
          "123e4567-e89b-12d3-a456-4266-14174000",
          # Trailing hyphen
          "123e4567-e89b-12d3-a456-42661417400-",
          # Leading hyphen
          "-123e4567-e89b-12d3-a456-426614174000",
          # Trailing space
          "123e4567-e89b-12d3-a456-426614174000 ",
          # Leading space
          " 123e4567-e89b-12d3-a456-426614174000"
        ]
      )
    end

    test "uri" do
      run_cases(
        "uri",
        # valids
        [
          "http://example.com",
          "https://example.com"
        ],
        # invalids
        [
          # Control characters
          ~S"http://www.example.com/\x07test",
          # Invalid percent-encoding
          ~S"http://www.example.com/%ZZtest",
          # Invalid syntax with port
          ~S"http://www.example.com:80:80/test",
          # Disallowed characters
          ~S"http://www.example.com/<>test",
          # Unbalanced brackets for IPv6
          ~S"http://[2001:db8::1/test"
        ]
      )
    end

    test "uri-reference" do
      run_cases(
        "uri-reference",
        # valids
        [
          "http://example.com",
          "https://example.com",
          "//example.com",
          "/some/path",
          "/some/path?k=v&ks%5B%5D=vv",
          # this will be a path
          "example.com"
        ],
        # invalids
        [
          # Unencoded square brackets
          "/some/path?k=v&ks[]=vv",
          # Control character in fragment
          ~S"http://www.example.com/path#\x07section",
          # Invalid percent-encoding in query
          ~S"http://www.example.com/path?query=%ZZ",
          # Disallowed characters in fragment
          ~S"http://www.example.com/path#<>section",
          # Disallowed characters in query
          ~S"http://www.example.com/path?query=<value>",
          # Unbalanced brackets in IPv6 address with fragment
          ~S"http://[2001:db8::1/path#section"
        ]
      )
    end

    test "iri" do
      run_cases(
        "iri",
        # valids
        [
          "http://héhé.com"
        ],
        # invalids

        [
          # Unescaped spaces
          ~S"http://www.example.com/some path/",
          # Control characters
          ~S"http://www.example.com/\x07test",
          # Invalid percent-encoding
          ~S"http://www.example.com/%ZZtest",
          # Invalid syntax with port
          ~S"http://www.example.com:80:80/test",
          # Disallowed characters
          ~S"http://www.example.com/<>test",
          # Unbalanced brackets for IPv6
          ~S"http://[2001:db8::1/test"
        ]
      )
    end

    test "iri-reference" do
      run_cases(
        "iri-reference",
        # valids
        [
          "http://héhé.com",
          "//héhé.com"
        ],
        # invalids
        [
          # Control character in fragment
          ~S"http://www.example.com/path#\x07section",
          # Invalid percent-encoding in query
          ~S"http://www.example.com/path?query=%ZZ",
          # Disallowed characters in fragment
          ~S"http://www.example.com/path#<>section",
          # Disallowed characters in query
          ~S"http://www.example.com/path?query=<value>",
          # Unbalanced brackets in IPv6 address with fragment
          ~S"http://[2001:db8::1/path#section"
        ]
      )
    end

    test "uri-template" do
      run_cases(
        "uri-template",
        # Valid URI templates
        [
          # Simple variable substitution
          "http://example.com/{id}",
          # Variable within path
          "http://example.com/{id}/details",
          # Query parameter expansion
          "http://example.com/search{?query,lang}",
          # Reserved expansion
          "http://example.com/{+path}",
          # Fragment expansion
          "http://example.com/{#fragment}",
          # Label expansion with dot-prefix
          "http://example.com/{.extension}",
          # Path segment expansion
          "http://example.com/{/segments*}",
          # Path-style expansion
          "http://example.com{/id*}",
          # Path-style parameter expansion
          "http://example.com/{;params*}",
          # Form-style query expansion
          "http://example.com{?list*}",
          # Form-style query continuation
          "http://example.com{&additional*}"
        ],

        # Invalid URI templates
        [
          # Missing closing brace
          "http://example.com/{id",
          # Missing opening brace
          "http://example.com/id}",
          # Space within variable name
          "http://example.com/{id name}",
          # Colon with no value or modifier
          "http://example.com/{id:}",
          # Non-numeric modifier
          "http://example.com/{id:abc}",
          # Reserved expansion without variable
          "http://example.com/{+}",
          # Fragment expansion without variable
          "http://example.com/{#}",
          # Path segment expansion without variable
          "http://example.com/{/}",
          # Path-style parameter expansion without variable
          "http://example.com/{;}",
          # Form-style query expansion without variable
          "http://example.com{?}",
          # Form-style query continuation without variable
          "http://example.com{&}",
          # Invalid prefix operator
          "http://example.com/{-prefix|}",
          # Invalid character in variable
          "http://example.com/{id/:name}",
          # Trailing comma in variable list
          "http://example.com/{id,}",
          # Double comma in variable list
          "http://example.com/{id,,name}"
        ]
      )
    end

    test "json-pointer" do
      run_cases(
        "json-pointer",
        # Valid JSON Pointers
        [
          # The whole document
          "",
          # Pointer to a member named "foo"
          "/foo",
          # Pointer to the first element of the array in "foo"
          "/foo/0",
          # Pointer to the root object's property named ""
          "/",
          # Pointer to the property named "a/b"
          "/a~1b",
          # Pointer to the property named "c%d"
          "/c%d",
          # Pointer to the property named "e^f"
          "/e^f",
          # Pointer to the property named "g|h"
          "/g|h",
          # Pointer to the property named "i\\j"
          "/i\\j",
          # Pointer to the property named "k\"l"
          "/k\"l",
          # Pointer to the property named " "
          "/ ",
          # Pointer to the property named "m~n"
          "/m~0n",
          # Nested object/property access
          "/foo/bar",
          # Deeply nested object/property access
          "/foo/bar/baz",
          # Array access followed by object access
          "/0/foo",
          # Complex nested and indexed access
          "/foo/0/bar/1"
        ],

        # Invalid JSON Pointers
        [
          # Incomplete escape sequence
          "/~",
          # Invalid escape sequence
          "/~2",
          # Missing leading slash
          "foo",
          # Invalid escape character
          "/foo/~x",
          # Invalid escape sequence
          "/foo/bar~0~3",
          # Incomplete escape sequence
          "/foo/~1~",
          # Incomplete escape after valid escape
          "/foo/bar~0~",
          # Invalid escape sequence
          "/foo/~bar",
          # Incomplete escape sequence in path
          "/foo/bar~"
        ]
      )
    end

    test "relative-json-pointer" do
      run_cases(
        "relative-json-pointer",
        # Valid Relative JSON Pointers
        [
          # Points to the current value
          "0",
          # Points to the parent of the current value
          "1",
          # Points to the first element of the array two levels up
          "2/0",
          # Points to the "foo" property of the parent
          "1/foo",
          # Points to the current value as a URI fragment
          "0#",
          # Complex navigation two levels up and into a nested object
          "2/0/foo",
          # Points to "baz" inside "bar" of the parent
          "1/bar/baz",
          # Complex navigation three levels up and into a nested path
          "3/1/foo/bar",
          # Points to "bar" inside "foo" at the current level
          "0/foo/bar",
          # Points to the first element of "foo" three levels up
          "3/foo/0"
        ],

        # Invalid Relative JSON Pointers
        [
          # Negative value not allowed
          "-1",
          # Missing numeric prefix
          "foo",
          # Incomplete escape sequence
          "1/foo~",
          # Incomplete escape sequence
          "2/0/foo~",
          # Missing slash after level
          "3foo",
          # Leading slash not allowed
          "/2/foo",
          # Non-numeric level
          "a1/foo",
          # Incomplete escape sequence
          "2/foo~0~",
          # Invalid escape character
          "2/0/~foo"
        ]
      )
    end

    test "regex" do
      run_cases(
        "regex",
        # Valid Elixir regex strings
        [
          # Matches one or more digits
          ~S/\d+/,
          # Matches "hello" at the start and end (exact match)
          ~S/^hello$/,
          # Matches a valid identifier (alphanumeric with underscores, starting with a letter or underscore)
          ~S/^[a-zA-Z_][a-zA-Z0-9_]*$/,
          # Matches one or more whitespace characters
          ~S/\s+/,
          # Matches either "foo" or "bar"
          ~S/(foo|bar)/,
          # Matches a simple email pattern
          ~S/^\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,3}$/,
          # Matches a URL
          ~S"\b(?:https?|ftp)://\S+\b",
          # Matches "elixir" case-insensitively
          ~S/(?i)elixir/,
          # Matches a string that does not contain "foo" or "bar"
          ~S/\A(?!.*\b(?:foo|bar)\b).*\Z/,
          # Matches non-greedy anything enclosed in brackets
          ~S/\[.*?\]/
        ],

        # Invalid Elixir regex strings
        [
          # Unmatched opening parenthesis
          ~S/(/,
          # Unmatched opening square bracket
          ~S/[a-z/,
          # Lone backslash
          <<?\\>>,
          # Unmatched opening parenthesis in group
          ~S/(foo|bar/,
          # Unmatched closing parenthesis
          ~S/foo)/,
          # Unmatched opening bracket in character class
          ~S/[0-9/,
          # Quantifier without preceding token
          ~S/{3}/,
          # Quantifier without preceding token
          ~S/*foo/,
          # Unmatched non-capturing group
          ~S/(?:foo|bar/,
          # Incorrect range in quantifier
          ~S/[a-zA-Z]{2,1}/,
          # Unmatched parenthesis
          ~S/(abc/,
          # Unmatched bracket
          ~S/[a-zA-Z/,
          # Misplaced modifier
          ~S/(?x foo/,
          # Unmatched parenthesis
          ~S/(foo|bar))/,
          # Invalid group type
          ~S/(?foo)/,
          # Quantifier without preceding token
          ~S/*/,
          # Invalid quantifier usage
          ~S/(**)/
        ]
      )
    end
  end
end
