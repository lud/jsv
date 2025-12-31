defmodule JSV.NullableTest do
  use ExUnit.Case, async: true

  import JSV.Schema.Helpers

  describe "nullable option" do
    test "string(nullable: true) accepts nil values" do
      schema = props(foo: string(nullable: true))
      root = JSV.build!(schema)

      # nil should be valid when nullable: true
      assert {:ok, _} = JSV.validate(%{"foo" => nil}, root)
    end

    test "string(nullable: true) still accepts string values" do
      schema = props(foo: string(nullable: true))
      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(%{"foo" => "hello"}, root)
    end

    test "string without nullable rejects nil values" do
      schema = props(foo: string())
      root = JSV.build!(schema)

      # nil should be invalid without nullable: true
      assert {:error, _} = JSV.validate(%{"foo" => nil}, root)
    end

    test "integer(nullable: true) accepts nil values" do
      schema = props(foo: integer(nullable: true))
      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(%{"foo" => nil}, root)
    end

    test "integer(nullable: true) still accepts integer values" do
      schema = props(foo: integer(nullable: true))
      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(%{"foo" => 42}, root)
    end

    test "boolean(nullable: true) accepts nil values" do
      schema = props(foo: boolean(nullable: true))
      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(%{"foo" => nil}, root)
    end

    test "number(nullable: true) accepts nil values" do
      schema = props(foo: number(nullable: true))
      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(%{"foo" => nil}, root)
    end
  end
end
