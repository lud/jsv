defmodule JSV.ArrayItemsTest do
  use ExUnit.Case, async: true

  defp findings(schema, data) do
    root = JSV.build!(schema)
    assert {:error, err} = JSV.validate(data, root)
    %{details: details} = JSV.normalize_error(err, sort: :asc)

    Enum.flat_map(details, fn unit ->
      Enum.map(unit.errors, fn error -> {unit.instanceLocation, error.kind, error.message} end)
    end)
  end

  describe "draft 2020-12" do
    test "casts each item at its own index" do
      root = JSV.build!(%{prefixItems: [%{type: :integer}, %{type: :string}], items: %{type: :integer}})

      assert {:ok, [1, "a", 3, 4]} = JSV.validate([1.0, "a", 3.0, 4.0], root)
    end

    test "items after prefixItems are not validated without an items schema" do
      root = JSV.build!(%{prefixItems: [%{type: :integer}, %{type: :integer}]})

      assert {:ok, [1, 2, "a", 4.0]} = JSV.validate([1.0, 2.0, "a", 4.0], root)
    end

    test "every invalid item is reported with its keyword, in index order" do
      schema = %{prefixItems: [%{type: :integer}, %{type: :string}], items: %{type: :integer}}

      assert [
               {"#", :prefixItems, "item at index 0 does not validate the 'prefixItems[0]' schema"},
               {"#", :prefixItems, "item at index 1 does not validate the 'prefixItems[1]' schema"},
               {"#", :items, "item at index 2 does not validate the 'items' schema"},
               {"#", :items, "item at index 3 does not validate the 'items' schema"},
               {"#/0", :type, _},
               {"#/1", :type, _},
               {"#/2", :type, _},
               {"#/3", :type, _}
             ] = findings(schema, ["x", 1, "y", "z"])
    end

    test "long lists keep their order" do
      root = JSV.build!(%{items: %{type: :integer}})
      data = Enum.map(1..1000, &(&1 * 1.0))

      assert {:ok, casted} = JSV.validate(data, root)
      assert casted == Enum.to_list(1..1000)
    end
  end

  describe "draft 7" do
    test "casts each item at its own index with items as a list and additionalItems" do
      root =
        JSV.build!(%{
          "$schema" => "http://json-schema.org/draft-07/schema#",
          "items" => [%{"type" => "integer"}, %{"type" => "string"}],
          "additionalItems" => %{"type" => "integer"}
        })

      assert {:ok, [1, "a", 3, 4]} = JSV.validate([1.0, "a", 3.0, 4.0], root)
    end

    test "casts each item at its own index with items as a schema" do
      root = JSV.build!(%{"$schema" => "http://json-schema.org/draft-07/schema#", "items" => %{"type" => "integer"}})

      assert {:ok, [1, 2, 3]} = JSV.validate([1.0, 2.0, 3.0], root)
    end

    test "every invalid item is reported with its keyword, in index order" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "items" => [%{"type" => "integer"}, %{"type" => "string"}],
        "additionalItems" => %{"type" => "integer"}
      }

      assert [
               {"#", :items_as_prefix, "item at index 0 does not validate the 'items[0]' schema"},
               {"#", :items_as_prefix, "item at index 1 does not validate the 'items[1]' schema"},
               {"#", :additionalItems, "item at index 2 does not validate the 'additionalItems' schema"},
               {"#", :additionalItems, "item at index 3 does not validate the 'additionalItems' schema"},
               {"#/0", :type, _},
               {"#/1", :type, _},
               {"#/2", :type, _},
               {"#/3", :type, _}
             ] = findings(schema, ["x", 1, "y", "z"])
    end
  end
end
