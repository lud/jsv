defmodule JSV.ValidTest do
  alias JSV.Schema
  import JSV.Schema.Helpers, only: [string_to_integer: 0]
  use JSV.Schema
  use ExUnit.Case, async: true

  defmodule Tag do
    defschema(%Schema{
      type: :object,
      properties: %{name: %{type: :string}},
      required: [:name]
    })
  end

  defmodule Line do
    defschema(%Schema{
      type: :object,
      properties: %{
        quantity: string_to_integer(),
        tags: %{type: :array, items: Tag}
      },
      required: [:quantity]
    })
  end

  defmodule Casts do
    use JSV.Schema

    defcast only_tags(list) do
      if Enum.all?(list, &is_struct(&1, Tag)) do
        {:ok, list}
      else
        {:error, :expected_tags}
      end
    end

    defcast never_called(_data) do
      ExUnit.Assertions.flunk("this should not be called")
    end

    defcast with_context(data, _args, vctx) do
      if is_struct(vctx, JSV.Validator.ValidationContext) do
        {:ok, data}
      else
        {:error, :expected_context}
      end
    end
  end

  defp root!(schema) do
    JSV.build!(schema, formats: true)
  end

  defp assert_agrees(root, data) do
    assert JSV.valid?(data, root) == match?({:ok, _}, JSV.validate(data, root))
  end

  test "returns true for valid data and false for invalid data" do
    root = root!(%{type: :object, required: [:name], properties: %{name: %{type: :string, minLength: 2}}})

    assert JSV.valid?(%{"name" => "ok"}, root)
    refute JSV.valid?(%{"name" => "x"}, root)
    refute JSV.valid?(%{}, root)
    refute JSV.valid?("not an object", root)
  end

  test "returns false when a nested cast fails" do
    root = root!(Line)

    assert JSV.valid?(%{"quantity" => "12", "tags" => [%{"name" => "a"}]}, root)
    refute JSV.valid?(%{"quantity" => "12a", "tags" => [%{"name" => "a"}]}, root)
    refute JSV.valid?(%{"quantity" => "12", "tags" => [%{"name" => 1}]}, root)
  end

  test "gives cast items to the cast of their parent" do
    root = root!(Schema.xcast(%{type: :array, items: Tag}, Casts.only_tags()))

    assert {:ok, [%Tag{name: "a"}, %Tag{name: "b"}]} = JSV.validate([%{"name" => "a"}, %{"name" => "b"}], root)
    assert JSV.valid?([%{"name" => "a"}, %{"name" => "b"}], root)
    refute JSV.valid?([%{"name" => "a"}, %{}], root)
  end

  test "does not call casts with cast: false, as validate/3" do
    root = root!(Line)
    data = %{"quantity" => "12a"}

    refute JSV.valid?(data, root)
    assert JSV.valid?(data, root, cast: false)
    assert {:ok, ^data} = JSV.validate(data, root, cast: false)
  end

  test "validates against the schema of the given key" do
    ctx = JSV.build_init!()
    {root_key, _, ctx} = JSV.build_add!(ctx, %{"$defs" => %{"positive" => %{type: :integer, minimum: 1}}})
    {root_key, ctx} = JSV.build_key!(ctx, root_key)
    {positive_key, ctx} = JSV.build_key!(ctx, JSV.Ref.parse!("#/$defs/positive", :root))
    root = JSV.to_root!(ctx, root_key)

    assert JSV.valid?(0, root)
    refute JSV.valid?(0, root, key: positive_key)
    assert JSV.valid?(1, root, key: positive_key)
  end

  test "rejects unknown options" do
    assert_raise ArgumentError, fn -> JSV.valid?(1, root!(%{}), feature_errors: true) end
  end

  test "gives a context to cast functions of arity 3" do
    root = root!(Schema.xcast(%{type: :string}, Casts.with_context([])))

    assert JSV.valid?("a", root)
    refute JSV.valid?(1, root)
  end

  test "accepts a combinator branch when another branch fails on a nested cast" do
    root = root!(%{anyOf: [Line, %{type: :object, required: [:fallback]}]})

    assert JSV.valid?(%{"quantity" => "12a", "fallback" => true}, root)
    refute JSV.valid?(%{"quantity" => "12a"}, root)
    assert_agrees(root, %{"quantity" => "12a", "fallback" => true})
  end

  test "applies else when the if condition fails on a nested cast" do
    root = root!(%{if: Line, then: %{required: [:then]}, else: %{required: [:else]}})

    then_valid = %{"quantity" => "12", "then" => true}
    else_valid = %{"quantity" => "12a", "else" => true}
    then_invalid = %{"quantity" => "12", "else" => true}
    else_invalid = %{"quantity" => "12a", "then" => true}

    assert {:ok, _} = JSV.validate(then_valid, root)
    assert {:ok, _} = JSV.validate(else_valid, root)
    assert {:error, _} = JSV.validate(then_invalid, root)
    assert {:error, _} = JSV.validate(else_invalid, root)

    assert JSV.valid?(then_valid, root)
    assert JSV.valid?(else_valid, root)
    refute JSV.valid?(then_invalid, root)
    refute JSV.valid?(else_invalid, root)
  end

  test "supports oneOf, allOf, not and if/then/else" do
    one_of = root!(%{oneOf: [%{type: :integer}, %{minimum: 5}]})
    assert JSV.valid?(3, one_of)
    refute JSV.valid?(7, one_of)
    assert JSV.valid?("str", one_of) == match?({:ok, _}, JSV.validate("str", one_of))

    all_of = root!(%{allOf: [%{type: :integer}, %{minimum: 5}]})
    assert JSV.valid?(6, all_of)
    refute JSV.valid?(4, all_of)

    negation = root!(%{not: Line})
    assert JSV.valid?(%{"quantity" => "12a"}, negation)
    refute JSV.valid?(%{"quantity" => "12"}, negation)

    conditional = root!(%{if: %{type: :integer}, then: %{minimum: 10}, else: %{type: :string}})
    assert JSV.valid?(10, conditional)
    refute JSV.valid?(9, conditional)
    assert JSV.valid?("a", conditional)
    refute JSV.valid?(true, conditional)
  end

  test "stops allOf at the first failing branch" do
    root = root!(%{allOf: [%{required: ["a"]}, %{properties: %{b: Schema.xcast(%{}, Casts.never_called())}}]})

    refute JSV.valid?(%{"b" => 1}, root)
  end

  test "counts the items that validate the contains schema" do
    root = root!(%{contains: Line, minContains: 2, maxContains: 2})

    lines = [%{"quantity" => "1"}, %{"quantity" => "x"}, %{"quantity" => "2"}]
    assert JSV.valid?(lines, root)
    refute JSV.valid?(tl(lines), root)
    refute JSV.valid?([%{"quantity" => "3"} | lines], root)
  end

  test "does not mark properties of a failing branch as evaluated" do
    root =
      root!(%{
        anyOf: [%{properties: %{a: %{type: :integer}}, required: [:b]}, %{}],
        unevaluatedProperties: false
      })

    refute JSV.valid?(%{"a" => 1}, root)
    assert JSV.valid?(%{}, root)
    assert_agrees(root, %{"a" => 1})
  end

  test "keeps tracking evaluated properties for unevaluatedProperties" do
    root =
      root!(%{
        properties: %{a: %{type: :integer}},
        allOf: [%{properties: %{b: %{type: :integer}}}],
        unevaluatedProperties: false
      })

    assert JSV.valid?(%{"a" => 1, "b" => 2}, root)
    refute JSV.valid?(%{"a" => 1, "b" => 2, "c" => 3}, root)
  end

  test "returns false when a pattern match exhausts its budget" do
    pattern = "^(?:(a+)+b|a+!)$"
    subject = String.duplicate("a", 20) <> "!"

    refute JSV.valid?(subject, root!(%{pattern: pattern}))
    refute JSV.valid?(subject, root!(%{not: %{pattern: pattern}}))
    refute JSV.valid?(%{subject => 1}, root!(%{patternProperties: %{pattern => %{type: :string}}}))
  end

  test "does not slow down with the depth of recursive data" do
    root =
      root!(%{
        "$id" => "http://example.com/recursive",
        "anyOf" => [%{"type" => "integer"}, %{"type" => "array", "items" => %{"$ref" => "#"}}]
      })

    nest = fn leaf -> Enum.reduce(1..5_000, leaf, fn _, acc -> [acc] end) end

    task = Task.async(fn -> {JSV.valid?(nest.(1), root), JSV.valid?(nest.("x"), root)} end)

    case Task.yield(task, 5_000) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> assert {true, false} = result
      nil -> flunk("valid? did not terminate within 5s")
    end
  end

  test "validates formats when enabled at build time" do
    root = root!(%{type: :string, format: :email})

    assert JSV.valid?("user@example.com", root)
    refute JSV.valid?("nope", root)
  end
end
