defmodule JSV.PatternBacktrackingTest do
  use ExUnit.Case, async: true

  # Schema-supplied regexes for `pattern` and `patternProperties` are matched
  # with a backtracking budget proportional to the subject size
  # (JSV.Helpers.RegexExt.bounded_match?/2). A match that exhausts the budget counts as
  # a non-match, so pathological pattern/data combinations produce a normal
  # validation result instead of burning ~200ms of CPU per match.

  # Classic catastrophic pattern: matching fails only after exponential
  # backtracking over the run of "a"s.
  @evil_pattern "^(a+)+$"

  defp evil_subject do
    String.duplicate("a", 3000) <> "!"
  end

  test "pattern returns a :pattern error on catastrophic input, quickly" do
    root = JSV.build!(%{"pattern" => @evil_pattern})

    assert {:ok, "aaaa"} = JSV.validate("aaaa", root)

    {us, result} = :timer.tc(fn -> JSV.validate(evil_subject(), root) end)
    assert {:error, %JSV.ValidationError{} = err} = result
    assert %{valid: false, details: [%{errors: [%{kind: :pattern}]}]} = JSV.normalize_error(err)
    assert us < 100_000
  end

  test "patternProperties does not amplify catastrophic backtracking over patterns x keys" do
    pattern_properties = Map.new(1..5, fn i -> {"^(a+)+#{i}$", %{"type" => "integer"}} end)
    root = JSV.build!(%{"patternProperties" => pattern_properties})

    assert {:ok, _} = JSV.validate(%{"aaa1" => 123}, root)
    assert {:error, _} = JSV.validate(%{"aaa1" => "not an integer"}, root)

    # 5 patterns x 5 catastrophic keys = 25 matches, ~200ms each at PCRE2
    # default limits (~5s total). The budget keeps the whole validation fast.
    data = Map.new(1..5, fn i -> {evil_subject() <> Integer.to_string(i), i} end)
    {us, result} = :timer.tc(fn -> JSV.validate(data, root) end)
    assert {:ok, _} = result
    assert us < 1_000_000
  end

  test "draft-7 pattern takes the same bounded path" do
    root = JSV.build!(%{"$schema" => "http://json-schema.org/draft-07/schema#", "pattern" => @evil_pattern})

    {us, result} = :timer.tc(fn -> JSV.validate(evil_subject(), root) end)
    assert {:error, %JSV.ValidationError{}} = result
    assert us < 100_000
  end
end
