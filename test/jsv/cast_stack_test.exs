# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.CastStackTest do
  use JSV.Schema
  use ExUnit.Case, async: true

  defmodule Cat do
    use JSV.Schema
    defschema kind: const("cat"), lives: integer()
  end

  defmodule Dog do
    use JSV.Schema
    defschema kind: const("dog"), good_boy: boolean()
  end

  defmodule Named do
    use JSV.Schema
    defschema name: string()
  end

  defmodule Aged do
    use JSV.Schema
    defschema age: integer()
  end

  defmodule Node do
    use JSV.Schema
    defschema value: string_to_integer(), child: optional(__MODULE__)
  end

  @cat %{"kind" => "cat", "lives" => 9}
  @dog %{"kind" => "dog", "good_boy" => true}

  test "oneOf casts with the branch that validates, after a failed branch" do
    root = JSV.build!(one_of([Cat, Dog]))

    assert {:ok, %Cat{kind: "cat", lives: 9}} == JSV.validate(@cat, root)
    assert {:ok, %Dog{kind: "dog", good_boy: true}} == JSV.validate(@dog, root)
    assert {:error, _} = JSV.validate(%{"kind" => "cow"}, root)
  end

  test "anyOf casts with the first branch that validates" do
    root = JSV.build!(any_of([Named, Aged]))

    assert {:ok, %Named{name: "al"}} == JSV.validate(%{"name" => "al", "age" => 3}, root)
    assert {:ok, %Aged{age: 3}} == JSV.validate(%{"age" => 3}, root)
  end

  test "if/then/else casts with the applied branch" do
    root = JSV.build!(%{if: %{type: :string}, then: string_to_integer(), else: Cat})

    assert {:ok, 12} == JSV.validate("12", root)
    assert {:ok, %Cat{kind: "cat", lives: 9}} == JSV.validate(@cat, root)
    assert {:error, _} = JSV.validate("not an integer", root)
  end

  test "anyOf branches cast property values" do
    root = JSV.build!(any_of([props(pet: Cat), props(pet: Dog)]))

    assert {:ok, %{"pet" => %Cat{kind: "cat", lives: 9}}} == JSV.validate(%{"pet" => @cat}, root)
    assert {:ok, %{"pet" => %Dog{kind: "dog", good_boy: true}}} == JSV.validate(%{"pet" => @dog}, root)
  end

  test "nested anyOf cast property values and the parent value is not cast" do
    root = JSV.build!(any_of([props(pet: any_of([Cat, Named])), props(pet: Dog)]))

    assert {:ok, %{"pet" => %Cat{kind: "cat", lives: 9}}} == JSV.validate(%{"pet" => @cat}, root)
    assert {:ok, %{"pet" => %Named{name: "n"}}} == JSV.validate(%{"pet" => %{"name" => "n"}}, root)
    assert {:ok, %{"pet" => %Dog{kind: "dog", good_boy: true}}} == JSV.validate(%{"pet" => @dog}, root)
  end

  test "oneOf branches cast array items" do
    root = JSV.build!(one_of([array_of(Cat), array_of(Dog)]))

    assert {:ok, [%Cat{kind: "cat", lives: 9}, %Cat{kind: "cat", lives: 9}]} == JSV.validate([@cat, @cat], root)
    assert {:ok, [%Dog{kind: "dog", good_boy: true}]} == JSV.validate([@dog], root)
    assert {:error, _} = JSV.validate([@cat, @dog], root)
  end

  test "dependentSchemas cast property values" do
    root = JSV.build!(%{type: :object, dependentSchemas: %{a: props(b: string_to_integer())}})

    assert {:ok, %{"a" => 1, "b" => 5}} == JSV.validate(%{"a" => 1, "b" => "5"}, root)
    assert {:ok, %{"b" => "5"}} == JSV.validate(%{"b" => "5"}, root)
  end

  test "recursive schemas cast every level" do
    root = JSV.build!(Node)
    data = %{"value" => "1", "child" => %{"value" => "2", "child" => %{"value" => "3"}}}

    assert {:ok, %Node{value: 1, child: %Node{value: 2, child: %Node{value: 3, child: nil}}}} ==
             JSV.validate(data, root)
  end

  test "not does not cast" do
    root = JSV.build!(%{not: Cat})

    assert {:ok, @dog} == JSV.validate(@dog, root)
    assert {:error, _} = JSV.validate(@cat, root)
  end

  test "contains does not cast items" do
    root = JSV.build!(%{contains: string_to_integer()})

    assert {:ok, ["1", "a"]} == JSV.validate(["1", "a"], root)
    assert {:error, _} = JSV.validate(["a"], root)
  end
end
