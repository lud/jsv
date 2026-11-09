defmodule JSV.RequiredTest do
  use ExUnit.Case, async: true

  test "reports the missing keys in schema order" do
    root = JSV.build!(%{required: [:c, :a, :b]})
    assert {:error, err} = JSV.validate(%{"a" => 1}, root)
    assert [%{errors: [%{kind: :required, message: message}]}] = JSV.normalize_error(err).details
    assert message == "properties 'c' and 'b' are required"
  end

  test "a key listed twice is not reported missing when present" do
    root = JSV.build!(%{"required" => ["a", "a"]})
    assert {:ok, _} = JSV.validate(%{"a" => 1}, root)
    assert {:error, _} = JSV.validate(%{}, root)
  end
end
