defmodule JSV.PatternBacktrackingTest do
  use ExUnit.Case, async: true

  # Schema-supplied regexes for `pattern` and `patternProperties` are matched
  # with a backtracking budget proportional to the subject size
  # (JSV.Helpers.RegexExt.bounded_match?/2). A match that exhausts the budget
  # is indeterminate. Treating it as a non-match could be inverted by `not`,
  # `anyOf`, etc., so the whole validation fails with an indeterminate error.

  # Classic catastrophic pattern: matching fails only after exponential
  # backtracking over the run of "a"s.
  @evil_pattern "^(a+)+$"

  # Matches through the second branch, but only after exponential backtracking
  # in the first one.
  @evil_matching_pattern "^(?:(a+)+b|a+!)$"

  defp evil_subject do
    String.duplicate("a", 3000) <> "!"
  end

  defp evil_matching_subject do
    String.duplicate("a", 20) <> "!"
  end

  defp assert_indeterminate(schema, data) do
    root = JSV.build!(schema)
    {us, result} = :timer.tc(fn -> JSV.validate(data, root) end)
    assert us < 100_000
    assert {:error, %JSV.ValidationError{} = err} = result
    assert %{valid: false, details: [unit]} = JSV.normalize_error(err)
    assert %{errors: [%{kind: :indeterminate_pattern, message: message}]} = unit
    refute message =~ "aaa"
    unit
  end

  test "pattern is indeterminate on catastrophic input, quickly" do
    root = JSV.build!(%{"pattern" => @evil_pattern})
    assert {:ok, "aaaa"} = JSV.validate("aaaa", root)

    assert_indeterminate(%{"pattern" => @evil_pattern}, evil_subject())
  end

  test "patternProperties is indeterminate on catastrophic keys, quickly" do
    pattern_properties = Map.new(1..5, fn i -> {"^(a+)+#{i}$", %{"type" => "integer"}} end)
    root = JSV.build!(%{"patternProperties" => pattern_properties})

    assert {:ok, _} = JSV.validate(%{"aaa1" => 123}, root)
    assert {:error, _} = JSV.validate(%{"aaa1" => "not an integer"}, root)

    data = Map.new(1..5, fn i -> {evil_subject() <> Integer.to_string(i), i} end)
    assert_indeterminate(%{"patternProperties" => pattern_properties}, data)
  end

  test "draft-7 pattern takes the same bounded path" do
    assert_indeterminate(
      %{"$schema" => "http://json-schema.org/draft-07/schema#", "pattern" => @evil_pattern},
      evil_subject()
    )
  end

  test "validate! raises the indeterminate error" do
    root = JSV.build!(%{"pattern" => @evil_pattern})

    assert_raise JSV.ValidationError, ~r/could not determine/, fn ->
      JSV.validate!(evil_subject(), root)
    end
  end

  # The budget is exhausted before PCRE reaches the matching branch. Treating
  # that as a non-match lets invalid data through.
  describe "exhausted budget on matching input" do
    setup do
      pp = %{"type" => "object", "patternProperties" => %{@evil_matching_pattern => %{"type" => "integer"}}}
      %{pp: pp, key: evil_matching_subject()}
    end

    test "the schemas behave correctly on a short matching input", %{pp: pp} do
      short = "aaa!"
      assert {:error, _} = JSV.validate(%{short => "not an int"}, JSV.build!(pp))
      assert {:error, _} = JSV.validate(short, JSV.build!(%{"not" => %{"pattern" => @evil_matching_pattern}}))
      assert {:ok, _} = JSV.validate(short, JSV.build!(%{"pattern" => @evil_matching_pattern}))
    end

    test "invalid data cannot bypass the patternProperties subschema", %{pp: pp, key: key} do
      unit = assert_indeterminate(pp, %{key => "not an int"})
      assert %{instanceLocation: "#", schemaLocation: "#/patternProperties"} = unit
    end

    test "invalid data cannot be validated by additionalProperties instead", %{pp: pp, key: key} do
      assert_indeterminate(Map.put(pp, "additionalProperties", %{"type" => "string"}), %{key => "not an int"})
    end

    test "invalid data cannot bypass a not-pattern deny-list", %{key: key} do
      unit = assert_indeterminate(%{"not" => %{"pattern" => @evil_matching_pattern}}, key)
      assert %{instanceLocation: "#", schemaLocation: "#/not"} = unit
    end

    test "invalid data cannot bypass a not-pattern deny-list in anyOf", %{key: key} do
      schema = %{"anyOf" => [%{"not" => %{"pattern" => @evil_matching_pattern}}, %{"const" => "other"}]}
      assert_indeterminate(schema, key)
    end

    test "invalid data cannot bypass a not-pattern deny-list on property names", %{key: key} do
      assert_indeterminate(%{"propertyNames" => %{"not" => %{"pattern" => @evil_matching_pattern}}}, %{key => 1})
    end

    test "pattern is indeterminate instead of rejecting valid data", %{key: key} do
      assert_indeterminate(%{"pattern" => @evil_matching_pattern}, key)
    end

    test "propertyNames is indeterminate instead of rejecting valid data", %{key: key} do
      assert_indeterminate(%{"propertyNames" => %{"pattern" => @evil_matching_pattern}}, %{key => 1})
    end

    test "additionalProperties false is indeterminate instead of rejecting valid data", %{pp: pp, key: key} do
      assert_indeterminate(Map.put(pp, "additionalProperties", false), %{key => 1})
    end
  end
end
