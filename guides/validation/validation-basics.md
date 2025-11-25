# Validate Data With Schemas



To validate a term, call the `JSV.validate/3` function like so:

```elixir
JSV.validate(data, root_schema, opts)
```

The return value of `JSV.validate/3` returns cast data. See the documentation of
that function for more information.


## General considerations

* JSV supports all keywords of the 2020-12 specification except
  `contentMediaType`, `contentEncoding` and `contentSchema`. They are ignored.
  Future support for custom vocabularies will allow you to validate data with
  such keywords.
* The `format` keyword is largely supported but with many inconsistencies,
  mostly due to differences between Elixir and JavaScript (JSON Schema is
  largely based on JavaScript primitives). For most use cases, the differences
  are negligible.
* The `"integer"` type will transform floats into integer when the fractional
  part is zero (such as `123.0`). Elixir implementation for floating-point
  numbers with large integer parts may return incorrect results. Example:

      > trunc(1000000000000000000000000.0)
      # ==>    999999999999999983222784

  When dealing with such data it may be better to discard the cast data, or to
  work with strings instead of floats.


## Formats

JSV supports multiple formats out of the box with its default implementation,
but some are only available under certain conditions that will be specified for
each format.

The following listing describes the condition for support and return value type
for these default implementations. You can override those implementations by
providing your own, as well as providing new formats. This will be described
later in this document.

Also, note that by default, JSV format validation will return the original
value, that is, the string form of the data. Some format validators can also
cast the string to a more interesting data structure, for instance converting a
date string to a `Date` struct. You can enable returning specific format cast
values by passing the `cast_formats: true` option to `JSV.validate/3`.

The listing below describe values returned when that option is enabled.

<!-- rdmx jsv:formats -->
### date

* **support**: Native.
* **input**: `"2020-04-22"`
* **output**: `~D[2020-04-22]`
* The format is implemented with the native `Date` module.
* The native `Date` module supports the `YYYY-MM-DD` format only. `2024`, `2024-W50`, `2024-12` will not be valid.

### date-time

* **support**: Native.
* **input**: `"2025-01-02T00:11:23.416689Z"`
* **output**: `~U[2025-01-02 00:11:23.416689Z]`
* The format is implemented with the native `DateTime` module.
* The native `DateTime` module supports the `YYYY-MM-DD` format only for dates. `2024T...`, `2024-W50T...`, `2024-12T...` will not be valid.
* Decimal precision is not capped to milliseconds. `2024-12-14T23:10:00.500000001Z` will be valid.

### duration

* **support**: Requires Elixir 1.17
* **input**: `"P1DT4,5S"`
* **output**: `%Duration{day: 1, second: 4, microsecond: {500000, 1}}`
* The format is implemented with the native `Duration` module.
* Elixir documentation states that _Only seconds may be specified with a decimal fraction, using either a comma or a full stop: P1DT4,5S_.
* Elixir durations accept negative values.
* Elixir durations accept out-of-range values, for instance more than 59 minutes.
* Excessive precision (as in `"PT10.0000000000001S"`) will be valid.

### email

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"hello@json-schema.org"`
* **output**: Input value.
* Support is limited by the implementation of that library.
* The `idn-email` format is not supported out-of-the-box.

### hostname

* **support**: Depends on `:idna` (automatically included)
* **input**: `"xn--zca29lwxobi7a"`
* **output**: Input value.

### ipv4

* **support**: Native.
* **input**: `"127.0.0.1"`
* **output**: `{127, 0, 0, 1}`
* The format is implemented with the native `:inet` module.

### ipv6

* **support**: Native.
* **input**: `"::1"`
* **output**: `{0, 0, 0, 0, 0, 0, 0, 1}`
* The format is implemented with the native `:inet` module.

### iri

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"https://héhé.com/héhé"`
* **output**: `%URI{scheme: "https", authority: "héhé.com", userinfo: nil, host: "héhé.com", port: 443, path: "/héhé", query: nil, fragment: nil}`

### iri-reference

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"//héhé"`
* **output**: `%URI{scheme: nil, authority: "héhé", userinfo: nil, host: "héhé", port: nil, path: nil, query: nil, fragment: nil}`

### json-pointer

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"/foo/bar/baz"`
* **output**: Input value.

### regex

* **support**: Native.
* **input**: `"[a-zA-Z0-9]"`
* **output**: `~r/[a-zA-Z0-9]/`
* The format is implemented with the native `Regex` module.
* The `Regex` module does not follow the `ECMA-262` specification.

### relative-json-pointer

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"0/foo/bar"`
* **output**: Input value.

### time

* **support**: Native.
* **input**: `"20:20:08.378586"`
* **output**: `~T[20:20:08.378586]`
* The format is implemented with the native `Time` module.
* The native `Time` implementation will completely discard the time offset information. Invalid offsets will be valid.
* Decimal precision is not capped to milliseconds. `23:10:00.500000001` will be valid.

### unknown

* **support**: Native
* **input**: `"anything"`
* **output**: Input value.
* No validation or transformation is done.

### uri

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"http://example.com"`
* **output**: `%URI{scheme: "http", authority: "example.com", userinfo: nil, host: "example.com", port: 80, path: nil, query: nil, fragment: nil}`
* The format is implemented with the native `URI` module.
* Without the optional dependency, the `URI` module is used and a minimum checks on hostname and scheme presence are made.

### uri-reference

* **support**: Depends on `:abnf_parsec` (automatically included)
* **input**: `"/example-path"`
* **output**: `%URI{scheme: nil, userinfo: nil, host: nil, port: nil, path: "/example-path", query: nil, fragment: nil}`
* The format is implemented with the native `URI` module.
* Without the optional dependency, the `URI` module will cast most non url-like strings as a `path`.

### uri-template

* **support**: Depends on `:texture` (automatically included)
* **input**: `"http://example.com/search{?query,lang}"`
* **output**: `%Texture.UriTemplate{}`

### uuid

* **support**: Native
* **input**: `"bf22824c-c8a4-11ef-9642-0fdaf117eeb9"`
* **output**: Input value.

<!-- rdmx /jsv:formats -->


## Custom formats

In order to provide custom formats, or to override default implementations for
formats, you may provide a list of modules as the value for the `:formats`
options of `JSV.build/2`. Such modules must implement the `JSV.FormatValidator`
behaviour.

### Example

```elixir
defmodule CustomFormats do
  @behaviour JSV.FormatValidator

  @impl true
  def supported_formats do
    ["greeting"]
  end

  @impl true
  def validate_cast("greeting", data) do
    case data do
      "hello " <> name -> {:ok, %Greeting{name: name}}
      _ -> {:error, :invalid_greeting}
    end
  end
end
```

With this module you can now call the builder with it:

```elixir
JSV.build!(raw_schema, formats: [CustomFormats])
```

Note that this will disable all other formats. If you need to still support the
default formats, a helper is available:

```elixir
JSV.build!(raw_schema,
  formats: [CustomFormats | JSV.default_format_validator_modules()]
)
```

Format validation modules are checked during the build phase, in order. So you
can override any format defined by a module that comes later in the list,
including the default modules.

