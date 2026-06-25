defmodule JSV.Helpers.RegexExtTest do
  use ExUnit.Case, async: true
  alias JSV.Helpers.RegexExt
  doctest JSV.Helpers.RegexExt

  # ECMA-262 patterns use Unicode property escapes such as `\p{Letter}`. Erlang's
  # regex engine (PCRE2) only accepts the *short* General_Category names (`\p{L}`),
  # so `translate_ecma_regex/1` rewrites the long names (and the `gc=`/
  # `General_Category=` equals-forms) into something PCRE2 can compile, while
  # leaving scripts and binary properties untouched.
  #
  # Full General_Category long -> short table (the closed set we must translate).
  @general_category [
    {"Letter", "L"},
    {"Cased_Letter", "LC"},
    {"Uppercase_Letter", "Lu"},
    {"Lowercase_Letter", "Ll"},
    {"Titlecase_Letter", "Lt"},
    {"Modifier_Letter", "Lm"},
    {"Other_Letter", "Lo"},
    {"Mark", "M"},
    {"Nonspacing_Mark", "Mn"},
    {"Spacing_Mark", "Mc"},
    {"Enclosing_Mark", "Me"},
    {"Number", "N"},
    {"Decimal_Number", "Nd"},
    {"Letter_Number", "Nl"},
    {"Other_Number", "No"},
    {"Punctuation", "P"},
    {"Connector_Punctuation", "Pc"},
    {"Dash_Punctuation", "Pd"},
    {"Open_Punctuation", "Ps"},
    {"Close_Punctuation", "Pe"},
    {"Initial_Punctuation", "Pi"},
    {"Final_Punctuation", "Pf"},
    {"Other_Punctuation", "Po"},
    {"Symbol", "S"},
    {"Math_Symbol", "Sm"},
    {"Currency_Symbol", "Sc"},
    {"Modifier_Symbol", "Sk"},
    {"Other_Symbol", "So"},
    {"Separator", "Z"},
    {"Space_Separator", "Zs"},
    {"Line_Separator", "Zl"},
    {"Paragraph_Separator", "Zp"},
    {"Other", "C"},
    {"Control", "Cc"},
    {"Format", "Cf"},
    {"Surrogate", "Cs"},
    {"Private_Use", "Co"},
    {"Unassigned", "Cn"}
  ]

  # Compiles the translated pattern the same way JSV's `pattern` keyword does,
  # raising if PCRE2 rejects it. The whole point of the translation is that the
  # output is always compilable.
  defp compile!(pattern) do
    pattern
    |> RegexExt.translate_ecma_regex()
    |> Regex.compile!()
  end

  describe "translate_ecma_regex/1 General_Category long names" do
    test "translates the regression case from the test suite" do
      assert RegexExt.translate_ecma_regex("^\\p{Letter}+$") == "^\\p{L}+$"
    end

    test "translates every long General_Category name to its short code" do
      for {long, short} <- @general_category do
        assert RegexExt.translate_ecma_regex("\\p{#{long}}") == "\\p{#{short}}",
               "expected \\p{#{long}} to translate to \\p{#{short}}"
      end
    end

    test "every translated General_Category name compiles under PCRE2" do
      for {long, _short} <- @general_category do
        assert %Regex{} = compile!("\\p{#{long}}"),
               "expected \\p{#{long}} to compile after translation"
      end
    end

    test "translates the negated form \\P{...}" do
      assert RegexExt.translate_ecma_regex("\\P{Letter}") == "\\P{L}"
      assert RegexExt.translate_ecma_regex("\\P{Decimal_Number}") == "\\P{Nd}"
    end

    test "translates multiple occurrences in a single pattern" do
      assert RegexExt.translate_ecma_regex("\\p{Letter}\\p{Number}") == "\\p{L}\\p{N}"
    end

    test "translates names embedded inside a larger pattern" do
      assert RegexExt.translate_ecma_regex("^[\\p{Letter}\\p{Mark}]{1,3}$") == "^[\\p{L}\\p{M}]{1,3}$"
    end
  end

  describe "translate_ecma_regex/1 equals-forms" do
    test "rewrites gc=<long> to a lone short code" do
      assert RegexExt.translate_ecma_regex("\\p{gc=Letter}") == "\\p{L}"
    end

    test "rewrites General_Category=<long> to a lone short code" do
      assert RegexExt.translate_ecma_regex("\\p{General_Category=Letter}") == "\\p{L}"
    end

    test "rewrites the equals-form even when the value is already short" do
      # PCRE2 rejects `\p{gc=L}` despite the value being short, so the equals
      # syntax itself must be removed.
      assert RegexExt.translate_ecma_regex("\\p{gc=L}") == "\\p{L}"
      assert %Regex{} = compile!("\\p{gc=L}")
    end

    test "rewrites the negated equals-form" do
      assert RegexExt.translate_ecma_regex("\\P{General_Category=Uppercase_Letter}") == "\\P{Lu}"
    end
  end

  describe "translate_ecma_regex/1 passthrough" do
    test "leaves short General_Category names unchanged" do
      for {_long, short} <- @general_category do
        pattern = "\\p{#{short}}"
        assert RegexExt.translate_ecma_regex(pattern) == pattern
      end
    end

    test "leaves script names unchanged (PCRE2 already accepts them)" do
      for pattern <- ["\\p{Latin}", "\\p{Latn}", "\\p{Script=Latin}", "\\p{Greek}"] do
        assert RegexExt.translate_ecma_regex(pattern) == pattern
        assert %Regex{} = compile!(pattern)
      end
    end

    test "leaves binary property names unchanged" do
      for pattern <- ["\\p{Alphabetic}", "\\p{Alpha}", "\\p{White_Space}", "\\p{Any}"] do
        assert RegexExt.translate_ecma_regex(pattern) == pattern
        assert %Regex{} = compile!(pattern)
      end
    end

    test "leaves patterns without property escapes unchanged" do
      for pattern <- ["", "^abc$", "[a-z]+\\d{2,4}", "ab\\.cd", "(foo|bar)?"] do
        assert RegexExt.translate_ecma_regex(pattern) == pattern
      end
    end

    test "is idempotent on already-translated patterns" do
      once = RegexExt.translate_ecma_regex("^\\p{Letter}\\p{gc=Number}$")
      assert RegexExt.translate_ecma_regex(once) == once
    end
  end

  describe "translate_ecma_regex/1 produces semantically correct regexes" do
    test "letter category matches letters and rejects digits" do
      re = compile!("^\\p{Letter}+$")
      assert Regex.match?(re, "abcXYZ")
      refute Regex.match?(re, "abc123")
    end

    test "decimal number category matches digits and rejects letters" do
      re = compile!("^\\p{Decimal_Number}+$")
      assert Regex.match?(re, "0123456789")
      refute Regex.match?(re, "12a")
    end

    test "negated letter category matches non-letters" do
      re = compile!("^\\P{Letter}+$")
      assert Regex.match?(re, "1234")
      refute Regex.match?(re, "12a4")
    end

    test "uppercase letter via equals-form matches only uppercase" do
      re = compile!("^\\p{General_Category=Uppercase_Letter}+$")
      assert Regex.match?(re, "ABC")
      refute Regex.match?(re, "ABc")
    end
  end

  describe "translate_ecma_regex/1 malformed property escapes" do
    test "leaves an unclosed property escape untouched" do
      assert RegexExt.translate_ecma_regex("^\\p{Letter") == "^\\p{Letter"
      assert RegexExt.translate_ecma_regex("\\P{gc=L") == "\\P{gc=L"
    end

    test "leaves empty braces untouched" do
      assert RegexExt.translate_ecma_regex("\\p{}") == "\\p{}"
    end

    test "translates a valid escape but leaves a later unclosed one untouched" do
      assert RegexExt.translate_ecma_regex("\\p{Letter}\\p{Number") == "\\p{L}\\p{Number"
    end
  end

  describe "translate_ecma_regex/1 property markers without braces" do
    test "leaves a bare \\p / \\P at end of string untouched" do
      assert RegexExt.translate_ecma_regex("\\p") == "\\p"
      assert RegexExt.translate_ecma_regex("\\P") == "\\P"
      assert RegexExt.translate_ecma_regex("x\\p") == "x\\p"
    end

    test "leaves a \\p / \\P not followed by a brace untouched" do
      assert RegexExt.translate_ecma_regex("a\\pb") == "a\\pb"
      assert RegexExt.translate_ecma_regex("a\\Pb") == "a\\Pb"
    end
  end
end
