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
end
