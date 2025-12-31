defmodule JSV.NullableTest do
  use ExUnit.Case, async: true

  import JSV.Schema.Helpers

  @nullable_tests [
    {:integer, 42},
    {:boolean, true},
    {:number, 3.14}
  ]

  describe "nullable option" do
    test "string(nullable: true) accepts nil values" do
      schema = props(foo: string(nullable: true))
      root = JSV.build!(schema)

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

      assert {:error, _} = JSV.validate(%{"foo" => nil}, root)
    end

    for {type_helper, valid_value} <- @nullable_tests do
      test "#{type_helper}(nullable: true) accepts nil and #{type_helper} values" do
        helper = unquote(type_helper)
        valid_value = unquote(valid_value)

        schema = props(foo: apply(JSV.Schema.Helpers, helper, [[nullable: true]]))
        root = JSV.build!(schema)

        assert {:ok, _} = JSV.validate(%{"foo" => nil}, root)
        assert {:ok, _} = JSV.validate(%{"foo" => valid_value}, root)
      end
    end
  end
end
