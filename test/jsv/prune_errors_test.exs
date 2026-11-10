defmodule JSV.PruneErrorsTest do
  alias JSV.ValidationError
  use ExUnit.Case, async: true

  defp error(schema, data) do
    assert {:error, err} = JSV.validate(data, JSV.build!(schema))
    err
  end

  defp normalized(err) do
    JSV.normalize_error(err, sort: :asc)
  end

  defp pruned(schema, data, max_errors) do
    schema |> error(data) |> ValidationError.prune_errors(max_errors: max_errors) |> normalized()
  end

  defp full(schema, data) do
    schema |> error(data) |> normalized()
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

  test "keeps all errors with max_errors: :infinity" do
    err = error(%{items: %{type: :integer}}, @strings)
    assert err == ValidationError.prune_errors(err, max_errors: :infinity)
    assert err == ValidationError.prune_errors(err, [])
  end

  test "rejects invalid options" do
    err = error(%{type: :integer}, "x")

    assert_raise ArgumentError, ~r/invalid value for option :max_errors/, fn ->
      ValidationError.prune_errors(err, max_errors: 0)
    end

    assert_raise ArgumentError, fn -> ValidationError.prune_errors(err, max: 1) end
  end

  test "normalize_error/2 accepts max_errors" do
    err = error(%{items: %{type: :integer}}, @strings)
    expected = err |> ValidationError.prune_errors(max_errors: 3) |> normalized()
    assert expected == JSV.normalize_error(err, sort: :asc, max_errors: 3)
  end
end
