defmodule JSV.ObjectPropertiesTest do
  use ExUnit.Case, async: true

  @draft7 "http://json-schema.org/draft-07/schema#"

  defp findings(schema, data) do
    root = JSV.build!(schema)
    assert {:error, err} = JSV.validate(data, root)
    %{details: details} = JSV.normalize_error(err, sort: :asc)

    Enum.flat_map(details, fn unit ->
      Enum.map(unit.errors, fn error -> {unit.instanceLocation, error.kind, error.message} end)
    end)
  end

  describe "draft 2020-12" do
    test "casts each property and keeps the other values" do
      root =
        JSV.build!(%{
          properties: %{a: %{type: :integer}, b: %{type: :string}},
          additionalProperties: %{type: :integer}
        })

      assert {:ok, %{"a" => 1, "b" => "x", "c" => 2}} = JSV.validate(%{"a" => 1.0, "b" => "x", "c" => 2.0}, root)
    end

    test "keys matched by properties or patternProperties are not additional" do
      root =
        JSV.build!(%{
          properties: %{a: %{type: :integer}},
          patternProperties: %{"^x-" => %{type: :string}},
          additionalProperties: false
        })

      assert {:ok, _} = JSV.validate(%{"a" => 1, "x-1" => "s"}, root)
      assert {:error, _} = JSV.validate(%{"a" => 1, "x-1" => "s", "b" => 1}, root)
    end

    test "every invalid property is reported with its keyword" do
      schema = %{
        properties: %{a: %{type: :integer}},
        patternProperties: %{"^x-" => %{type: :string}},
        additionalProperties: %{type: :integer}
      }

      assert [
               {"#", :patternProperties,
                "property 'x-1' did not conform to the patternProperties schema for pattern /^x-/"},
               {"#", :properties, "property 'a' did not conform to the property schema"},
               {"#", :additionalProperties, "property 'z' did not conform to the additionalProperties schema"},
               {"#/a", :type, _},
               {"#/x-1", :type, _},
               {"#/z", :type, _}
             ] = findings(schema, %{"a" => "no", "x-1" => 1, "z" => "no"})
    end

    test "objects with more than 32 keys validate every property" do
      keys = Enum.map(1..40, &"k#{&1}")
      schema = %{properties: Map.new(keys, &{&1, %{type: :integer}}), additionalProperties: false}
      root = JSV.build!(schema)

      assert {:ok, casted} = JSV.validate(Map.new(keys, &{&1, 1.0}), root)
      assert casted == Map.new(keys, &{&1, 1})

      invalid = keys |> Map.new(&{&1, 1}) |> Map.put("k33", "x")
      assert [{"#", :properties, _}, {"#/k33", :type, _}] = findings(schema, invalid)
    end
  end

  describe "draft 7" do
    test "casts each property and keeps the other values" do
      root =
        JSV.build!(%{
          "$schema" => @draft7,
          "properties" => %{"a" => %{"type" => "integer"}},
          "patternProperties" => %{"^x-" => %{"type" => "string"}},
          "additionalProperties" => %{"type" => "integer"}
        })

      assert {:ok, %{"a" => 1, "x-1" => "s", "c" => 2}} = JSV.validate(%{"a" => 1.0, "x-1" => "s", "c" => 2.0}, root)
    end
  end
end
