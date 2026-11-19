defmodule JSV.PruneErrorsTest do
  alias JSV.ErrorFormatter
  alias JSV.ValidationError
  alias JSV.Validator.Error
  use ExUnit.Case, async: true

  defp error(schema, data) do
    assert {:error, err} = JSV.validate(data, JSV.build!(schema))
    err
  end

  defp normalized(err, min_level \\ 0) do
    JSV.normalize_error(err, sort: :asc, min_error_level: min_level)
  end

  defp pruned(schema, data, max_errors) do
    schema |> error(data) |> ValidationError.prune_errors(max_errors: max_errors) |> normalized()
  end

  defp full(schema, data, min_level \\ 0) do
    schema |> error(data) |> normalized(min_level)
  end

  defp args_levels(errors) do
    Enum.flat_map(:lists.flatten(errors), fn %Error{args: args} ->
      [Keyword.get(args, :level, ErrorFormatter.level_cause()) | Enum.flat_map(args, &branch_levels/1)]
    end)
  end

  defp branch_levels({:invalidated, branches}) do
    Enum.flat_map(branches, fn {_, errors} -> args_levels(errors) end)
  end

  defp branch_levels({key, errors}) when key in [:err_if_errors, :after_errors] do
    args_levels(errors)
  end

  defp branch_levels(_) do
    []
  end

  defp error_at(kind, data_path, args) do
    %Error{
      kind: kind,
      data: nil,
      args: args,
      formatter: __MODULE__,
      data_path: data_path,
      eval_path: [],
      schema_path: [:root]
    }
  end

  @strings Enum.map(1..10, &"item#{&1}")

  test "keeps the first invalid items and their wrappers" do
    schema = %{items: %{type: :integer}}
    assert pruned(schema, @strings, 3) == full(schema, Enum.take(@strings, 3))
  end

  test "keeps the first invalid properties in key order" do
    schema = %{properties: Map.new(~w(a b c d), &{&1, %{type: :integer}})}
    data = Map.new(~w(d c b a), &{&1, "x"})
    assert pruned(schema, data, 2) == full(schema, %{"a" => "x", "b" => "x"})
  end

  test "keeps the errors on the parents of the kept locations" do
    schema = %{
      required: ["z"],
      properties: %{list: %{contains: %{type: :integer}, items: %{type: :integer}}, other: %{type: :integer}}
    }

    data = %{"list" => @strings, "other" => "x"}
    assert pruned(schema, data, 1) == full(schema, %{"list" => Enum.take(@strings, 1)})
  end

  test "keeps the errors of false schemas with their wrappers" do
    schema = %{properties: %{a: false, b: false}, additionalProperties: false, propertyNames: %{maxLength: 1}}
    data = %{"a" => 1, "b" => 1, "cc" => 1, "dd" => 1}
    assert pruned(schema, data, 3) == full(schema, %{"a" => 1, "b" => 1, "cc" => 1})
  end

  test "keeps every location when there are fewer than the limit" do
    schema = %{items: %{anyOf: [%{type: :integer}, %{type: :boolean}]}}
    assert pruned(schema, @strings, 100) == full(schema, @strings)
  end

  test "prunes the branch errors of anyOf, oneOf and allOf" do
    for kind <- [:anyOf, :oneOf, :allOf] do
      schema = %{kind => [%{items: %{type: :integer}}, %{items: %{type: :boolean}}]}
      assert pruned(schema, @strings, 2) == full(schema, Enum.take(@strings, 2))
    end
  end

  test "prunes the branch errors of if" do
    then_schema = %{if: %{type: :array}, then: %{items: %{type: :integer}}}
    assert pruned(then_schema, @strings, 2) == full(then_schema, Enum.take(@strings, 2))

    else_schema = %{if: %{items: %{type: :integer}}, else: %{items: %{type: :boolean}}}
    assert pruned(else_schema, @strings, 2) == full(else_schema, Enum.take(@strings, 2))
  end

  test "prunes nested branch errors" do
    schema = %{anyOf: [%{type: :integer}, %{items: %{anyOf: [%{type: :integer}, %{type: :boolean}]}}]}
    assert pruned(schema, @strings, 2) == full(schema, Enum.take(@strings, 2))
  end

  test "prunes the draft 7 items keywords" do
    list_schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      items: [%{type: :integer}, %{type: :integer}]
    }

    assert pruned(list_schema, ["a", "b"], 1) == full(list_schema, ["a", 1])

    additional_schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      items: [%{type: :integer}],
      additionalItems: %{type: :integer}
    }

    assert pruned(additional_schema, @strings, 2) == full(additional_schema, Enum.take(@strings, 2))
  end

  test "a level 5 error with a key or index follows its child" do
    wrapper_a = error_at(:custom, [], key: "a", level: 5)
    wrapper_b = error_at(:custom, [], key: "b", level: 5)
    item_wrapper = error_at(:custom, [], index: 0, level: 5)
    cause_with_key = error_at(:custom, [], key: "b")
    cause_a = error_at(:custom, ["a"], [])
    cause_b = error_at(:custom, ["b"], [])
    cause_0 = error_at(:custom, [0], [])

    err = ValidationError.of([wrapper_a, wrapper_b, item_wrapper, cause_with_key, cause_a, cause_b, cause_0])

    assert %ValidationError{errors: [item_wrapper, cause_with_key, cause_0]} ==
             ValidationError.prune_errors(err, max_errors: 1)
  end

  test "drops the errors below min_error_level, in the branches too" do
    schema = %{anyOf: [%{type: :integer}, %{items: %{anyOf: [%{type: :integer}, %{items: %{type: :integer}}]}}]}
    err = error(schema, Enum.map(@strings, &[&1]))
    assert 5 in args_levels(err.errors)

    pruned = ValidationError.prune_errors(err, min_error_level: 10)
    assert [10] == Enum.uniq(args_levels(pruned.errors))
    assert normalized(pruned, 10) == normalized(err, 10)
  end

  test "filters levels before picking the locations" do
    schema = %{properties: %{a: %{items: %{type: :integer}}}, required: ["z"]}
    err = error(schema, %{"a" => @strings})
    pruned = ValidationError.prune_errors(err, min_error_level: 10, max_errors: 2)

    assert [10, 10, 10] == args_levels(pruned.errors)
    assert normalized(pruned) == full(schema, %{"a" => Enum.take(@strings, 2)}, 10)
  end

  test "the pruned error does not grow with the number of invalid items" do
    schema = %{items: %{anyOf: [%{type: :integer}, %{type: :boolean}]}}

    size = fn n ->
      schema
      |> error(Enum.take(@strings, n))
      |> ValidationError.prune_errors(max_errors: 2)
      |> :erlang.term_to_binary()
      |> byte_size()
    end

    assert size.(10) == size.(2)
  end

  test "returns the error unchanged without options" do
    err = error(%{anyOf: [%{properties: %{a: %{type: :integer}, b: %{type: :integer}}}]}, %{"a" => "x", "b" => "y"})
    assert err === ValidationError.prune_errors(err, [])
    assert err === ValidationError.prune_errors(err, max_errors: :infinity)
  end

  test "applies an explicit min_error_level of 0" do
    negative = error_at(:custom, [], level: -1)
    cause = error_at(:custom, ["a"], [])
    err = ValidationError.of([negative, cause])

    assert %ValidationError{errors: [^negative, ^cause]} = ValidationError.prune_errors(err, max_errors: 5)
    assert %ValidationError{errors: [^cause]} = ValidationError.prune_errors(err, min_error_level: 0)
  end

  test "rejects invalid options" do
    err = error(%{type: :integer}, "x")

    assert_raise ArgumentError, ~r/invalid value for option :max_errors/, fn ->
      ValidationError.prune_errors(err, max_errors: 0)
    end

    assert_raise ArgumentError, ~r/invalid value for option :min_error_level/, fn ->
      ValidationError.prune_errors(err, min_error_level: :high)
    end

    assert_raise ArgumentError, fn -> ValidationError.prune_errors(err, max: 1) end
  end

  test "normalize_error/2 prunes with min_error_level and max_errors" do
    err = error(%{items: %{type: :integer}}, @strings)
    expected = err |> ValidationError.prune_errors(min_error_level: 10, max_errors: 3) |> normalized()
    assert expected == JSV.normalize_error(err, sort: :asc, min_error_level: 10, max_errors: 3)
    assert [_, _, _] = expected.details
  end
end
