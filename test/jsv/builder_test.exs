defmodule JSV.BuilderTest do
  alias JSV.Key
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

  describe "building multi-entrypoint schemas" do
    test "can build a schema with an deep entrypoint" do
      document = %{
        some: "stuff",
        nested: %{map: %{with: %{schema: %{type: "integer"}}}}
      }

      IO.warn("TODO")

      # assert {:ok, root} =
      #          JSV.build(document,
      #            entrypoints: [
      #              "#/nested/map/with/schema"
      #            ]
      #          )

      # assert {:ok, 123} = JSV.validate(123, root)
      # assert {:error, _} = JSV.validate("not an int", root)
    end
  end
end
