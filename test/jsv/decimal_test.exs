defmodule JSV.DecimalTest do
  use ExUnit.Case, async: true

  describe "supports multiple of with Decimal" do
    # The Decimal library is loaded in tests, so the multiple will always be
    # checked with Decimal.

    test "test supports edge cases" do
      root =
        JSV.build!(%{
          type: :object,
          properties: %{
            multipleOf01: %{multipleOf: 0.1},
            multipleOf001: %{multipleOf: 0.01}
          },
          required: [:multipleOf01, :multipleOf001]
        })

      # test with normal data
      normal_data = %{"multipleOf001" => 4.02, "multipleOf01" => 0.3}
      assert normal_data == JSV.validate!(normal_data, root)

      # test with decimal data
      decimal_data = %{"multipleOf01" => Decimal.new("0.3"), "multipleOf001" => Decimal.new("4.02")}
      assert decimal_data == JSV.validate!(decimal_data, root)
    end
  end

  describe "supports unique items with Decimal" do
    # JSON Schema compares numbers by mathematical value, and its data model
    # makes no distinction between integers and other numbers. Decimals with a
    # zero fractional part are therefore equal to the corresponding integer.

    setup do
      {:ok, root: JSV.build!(%{type: :array, uniqueItems: true})}
    end

    test "decimals with a zero fractional part duplicate an integer", %{root: root} do
      assert {:error, _} = JSV.validate([Decimal.new("1"), 1], root)
      assert {:error, _} = JSV.validate([Decimal.new("1.0"), 1], root)
      assert {:error, _} = JSV.validate([1, Decimal.new("1.000")], root)
      assert {:error, _} = JSV.validate([Decimal.new("1.0E+3"), 1000], root)
    end

    test "trailing zeros are insignificant between decimals", %{root: root} do
      assert {:error, _} = JSV.validate([Decimal.new("1.5"), Decimal.new("1.50")], root)
    end

    test "mathematically distinct numbers stay unique", %{root: root} do
      data = [Decimal.new("1.0"), Decimal.new("1.5"), Decimal.new("15"), 2]
      assert data == JSV.validate!(data, root)
    end
  end
end
