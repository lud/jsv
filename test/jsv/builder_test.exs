defmodule JSV.BuilderTest do
  use ExUnit.Case, async: true

  describe "resolving base meta schemas" do
    test "the default resolver can resolve draft 7" do
      raw_schema = %{"$schema" => "http://json-schema.org/draft-07/schema#", "type" => "integer"}
      assert {:ok, root} = JSV.build(raw_schema)
      assert {:ok, 1} = JSV.validate(1, root)
    end

    test "the default resolver can resolve draft 7 without trailing #" do
      raw_schema = %{"$schema" => "http://json-schema.org/draft-07/schema", "type" => "integer"}
      assert {:ok, root} = JSV.build(raw_schema)
      assert {:ok, 1} = JSV.validate(1, root)
    end

    test "the default resolver can resolve draft 2020-12" do
      raw_schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "type" => "integer"}
      assert {:ok, root} = JSV.build(raw_schema)
      assert {:ok, 1} = JSV.validate(1, root)
    end
  end
end
