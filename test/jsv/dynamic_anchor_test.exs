# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.DynamicAnchorTest do
  use ExUnit.Case, async: true

  describe "$dynamicAnchor without an enclosing $id" do
    # A schema resource is not required to declare an $id. The root schema is a
    # valid resource on its own, so a $dynamicAnchor defined under an id-less
    # root must be found by a $dynamicRef from the same resource.

    test "builds and validates when the anchor lives in the id-less root resource" do
      schema = %{
        "$defs" => %{
          "a" => %{"$dynamicAnchor" => "node", "allOf" => [%{"$dynamicRef" => "#node"}]}
        },
        "$ref" => "#/$defs/a"
      }

      assert {:ok, root} = JSV.build(schema)
      assert {:ok, %{}} = JSV.validate(%{}, root)
    end

    test "dynamic resolution works from an id-less root resource" do
      # The $dynamicRef must actually follow the dynamic anchor, not be ignored:
      # "items" applies the anchored subschema, so non-integer items are invalid.
      schema = %{
        "$defs" => %{
          "num" => %{"$dynamicAnchor" => "node", "type" => "integer"}
        },
        "items" => %{"$dynamicRef" => "#node"}
      }

      assert {:ok, root} = JSV.build(schema)
      assert {:ok, [1, 2]} = JSV.validate([1, 2], root)
      assert {:error, _} = JSV.validate(["nope"], root)
    end
  end

  describe "draft 7" do
    test "$dynamicAnchor and $dynamicRef are not keywords and are ignored" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "definitions" => %{
          "num" => %{"$dynamicAnchor" => "node", "type" => "integer"}
        },
        "properties" => %{"x" => %{"$dynamicRef" => "#node"}}
      }

      assert {:ok, root} = JSV.build(schema)

      # $dynamicRef is ignored in draft 7, so "x" accepts anything.
      assert {:ok, %{"x" => "some string"}} = JSV.validate(%{"x" => "some string"}, root)
    end
  end
end
