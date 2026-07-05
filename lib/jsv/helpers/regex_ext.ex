defmodule JSV.Helpers.RegexExt do
  @moduledoc """
  Helpers to compile and run ECMA-262 regular expressions (the dialect used by
  JSON Schema `pattern` and `patternProperties`) with Erlang's regex engine.

  Erlang's `:re` (PCRE2) accepts Unicode script and binary property names, but
  rejects the long General_Category names that ECMA-262 allows, such as
  `\\p{Letter}` or `\\p{General_Category=Number}`. `translate_ecma_regex/1`
  rewrites those into the short codes PCRE2 understands (`\\p{L}`, `\\p{N}`),
  leaving everything else untouched.
  """

  @doc ~S"""
  Rewrites the Unicode property escapes of an ECMA-262 regular expression into
  the equivalent escapes understood by Erlang's `:re` engine.

  ## Examples

      iex> JSV.Helpers.RegexExt.translate_ecma_regex("^\\p{Letter}+$")
      "^\\p{L}+$"

      iex> JSV.Helpers.RegexExt.translate_ecma_regex("\\p{General_Category=Number}")
      "\\p{N}"

      iex> JSV.Helpers.RegexExt.translate_ecma_regex("\\p{Latin}")
      "\\p{Latin}"

  """
  @spec translate_ecma_regex(binary) :: binary
  def translate_ecma_regex(ecma_regex) when is_binary(ecma_regex) do
    parse_translate(ecma_regex, <<>>)
  end

  # Backtracking budget for a match. Legitimate matches consume roughly 3
  # steps per subject byte, so the per-byte factor leaves a wide margin while
  # keeping the budget linear in the subject size. Pathological patterns such
  # as ^(a+)+$ need an exponential number of steps and exhaust the budget
  # immediately. The cap is PCRE2's default MATCH_LIMIT.
  @base_match_limit 10_000
  @match_limit_per_byte 50
  @max_match_limit 10_000_000

  @doc """
  Returns whether `regex` matches `subject`, like `Regex.match?/2`, but with a
  backtracking budget proportional to the subject size.

  Schema-supplied `pattern` and `patternProperties` regexes can require
  catastrophic backtracking on crafted data. This function bounds the match
  cost linearly in `byte_size(subject)`; a match that exhausts the budget is
  reported as a non-match.
  """
  @spec bounded_match?(Regex.t(), binary) :: boolean
  def bounded_match?(%Regex{re_pattern: re_pattern}, subject) when is_binary(subject) do
    limit = min(@max_match_limit, @base_match_limit + @match_limit_per_byte * byte_size(subject))

    :re.run(subject, re_pattern, [{:match_limit, limit}, {:match_limit_recursion, limit}, {:capture, :none}]) ==
      :match
  end

  defp parse_translate(<<?\\, p, ?{, rest::binary>>, acc) when p in [?p, ?P] do
    case take_until(rest, ?}, <<>>) do
      {:none, rest} ->
        <<acc::binary, ?\\, p, ?{, rest::binary>>

      {class, <<?}, rest::binary>>} ->
        parse_translate(rest, <<acc::binary, ?\\, p, ?{, translate_class(class)::binary, ?}>>)
    end
  end

  defp parse_translate(<<c::utf8, rest::binary>>, acc) do
    parse_translate(rest, <<acc::binary, c::utf8>>)
  end

  defp parse_translate(<<>>, acc) do
    acc
  end

  defp take_until(<<c::utf8, rest::binary>>, c, acc) do
    {acc, <<c, rest::binary>>}
  end

  defp take_until(<<char::utf8, rest::binary>>, c, acc) do
    take_until(rest, c, <<acc::binary, char::utf8>>)
  end

  defp take_until(<<>>, _, acc) do
    {:none, acc}
  end

  defp translate_class(class)

  genecal_categories = [
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

  Enum.each(genecal_categories, fn {long, short} ->
    defp translate_class(unquote(long)) do
      unquote(short)
    end
  end)

  defp translate_class("gc=" <> class) do
    translate_class(class)
  end

  defp translate_class("General_Category=" <> class) do
    translate_class(class)
  end

  defp translate_class(class) do
    class
  end
end
