defmodule JSV.AtomToolsTest do
  alias JSV.AtomTools
  alias JSV.Schema
  use ExUnit.Case, async: true

  doctest AtomTools, import: true

  test "remove all atoms from map" do
    # handles maps with atom keys
    assert %{"hello" => "world"} == AtomTools.deatomize(%{hello: "world"})

    # handles maps with atom values
    assert %{"hello" => "world"} == AtomTools.deatomize(%{hello: :world})

    # keeps booleans and nil as values but not keys
    assert %{"true" => true} == AtomTools.deatomize(%{true: true})
    assert %{"false" => false} == AtomTools.deatomize(%{false: false})
    assert %{"nil" => nil} == AtomTools.deatomize(%{nil: nil})

    # keeps basic types
    assert %{"i" => 1, "f" => 2.3, "l" => [4]} == AtomTools.deatomize(%{i: 1, f: 2.3, l: [4]})
  end

  test "removes all atoms and nil values from Schema struct" do
    # handles structs with a special treatment for the schema struct, it removes
    # all nil values.

    assert %{"title" => "stuff"} == AtomTools.deatomize(%Schema{title: "stuff"})

    assert %{"anyOf" => [%{"properties" => %{"foo" => 1}}]} ==
             AtomTools.deatomize(%Schema{anyOf: [%Schema{properties: %{foo: 1}}]})
  end

  defmodule MyStruct do
    defstruct a: nil, b: nil
  end

  test "removes struct fields from any struct" do
    # It does not removes nil values as for JSV.Schema

    assert %{"a" => "hello", "b" => nil} == AtomTools.deatomize(%MyStruct{a: "hello"})

    assert %{"a" => "hello", "b" => %{"a" => "goodbye", "b" => nil}} ==
             AtomTools.deatomize(%MyStruct{a: "hello", b: %MyStruct{a: "goodbye"}})
  end

  test "contains atoms check" do
    assert AtomTools.atom_props?(%{a: 1})
    assert AtomTools.atom_props?(%{a: 1, b: 2})
    refute AtomTools.atom_props?(%{"a" => 1})
    refute AtomTools.atom_props?(%{"a" => 1, "b" => 2})

    assert AtomTools.atom_props?(%{"a" => %{"b" => %{"c" => %{"d" => %{e: 1}}}}})
    assert AtomTools.atom_props?(%{"a" => %{"b" => %{"c" => %{"d" => %{"e" => :one}}}}})
    refute AtomTools.atom_props?(%{"a" => %{"b" => %{"c" => %{"d" => %{"e" => 1}}}}})

    assert AtomTools.atom_props?(%{"a" => :a})
    refute AtomTools.atom_props?(%{"a" => "a"})

    assert AtomTools.atom_props?([:a])
    refute AtomTools.atom_props?(~c"a")

    # handles basic types
    refute AtomTools.atom_props?(1)
    refute AtomTools.atom_props?("nope")
    assert AtomTools.atom_props?(:hello)

    # does not trigger on booleans/nil. See below for keys
    refute AtomTools.atom_props?(true)
    refute AtomTools.atom_props?(false)
    refute AtomTools.atom_props?(nil)

    # nested
    assert AtomTools.atom_props?([[%{"a" => %{"a" => %{"a" => [[[:hello]]]}}}]])

    # Does not return true for atom values if boolean/nil if not in key
    refute AtomTools.atom_props?(%{"foo" => true})
    refute AtomTools.atom_props?(%{"foo" => false})
    refute AtomTools.atom_props?(%{"foo" => nil})
    assert AtomTools.atom_props?(%{true: 1})
    assert AtomTools.atom_props?(%{false: 1})
    assert AtomTools.atom_props?(%{nil: 1})
  end

  test "converts modules that export schema/0 to refs" do
    defmodule ExportsSchema do
      @spec schema :: no_return()
      def schema do
        raise "will not be called"
      end
    end

    assert %{"$ref" => "jsv:module:#{Atom.to_string(ExportsSchema)}"} == AtomTools.deatomize(ExportsSchema)
  end

  test "converts modules that do not export schema/0 to string" do
    defmodule DoesNotExportSchema do
    end

    assert Atom.to_string(DoesNotExportSchema) == AtomTools.deatomize(DoesNotExportSchema)
  end
end
