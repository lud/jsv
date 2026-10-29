defmodule JSV.StringLengthTest do
  use ExUnit.Case, async: true

  # "e" followed by U+0301 COMBINING ACUTE ACCENT: 2 code points, 1 grapheme.
  @combining "e\u0301"

  # Family emoji joined with U+200D ZERO WIDTH JOINER: 5 code points, 1 grapheme.
  @zwj_sequence "\u{1F469}\u200D\u{1F469}\u200D\u{1F467}"

  defp valid?(schema, data) do
    match?({:ok, _}, JSV.validate(data, JSV.build!(schema)))
  end

  test "maxLength counts combining marks as separate code points" do
    refute valid?(%{maxLength: 1}, @combining)
    assert valid?(%{maxLength: 2}, @combining)
  end

  test "minLength counts combining marks as separate code points" do
    assert valid?(%{minLength: 2}, @combining)
    refute valid?(%{minLength: 3}, @combining)
  end

  test "zero width joiner sequences count every code point" do
    refute valid?(%{maxLength: 1}, @zwj_sequence)
    assert valid?(%{minLength: 5, maxLength: 5}, @zwj_sequence)
  end

  test "a supplementary plane character counts as one code point" do
    assert valid?(%{minLength: 1, maxLength: 1}, "\u{1F4A9}")
  end

  test "draft 7 counts code points" do
    schema = %{"$schema" => "http://json-schema.org/draft-07/schema#", "maxLength" => 1}
    refute valid?(schema, @combining)
  end

  test "error reports the length in code points" do
    root = JSV.build!(%{maxLength: 1})
    assert {:error, err} = JSV.validate(@combining, root)

    assert %{details: [%{errors: [%{kind: :maxLength, message: "value length must be at most 1 but is 2"}]}]} =
             JSV.normalize_error(err)
  end
end
