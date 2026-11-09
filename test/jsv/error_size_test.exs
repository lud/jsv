defmodule JSV.ErrorSizeTest do
  use ExUnit.Case, async: true

  @draft7 "http://json-schema.org/draft-07/schema#"
  @integer %{type: :integer}

  @list_kinds [:items, :prefixItems, :draft7_items, :draft7_items_array, :draft7_additionalItems]
  @map_kinds [:properties, :additionalProperties, :additionalProperties_false, :patternProperties, :propertyNames]

  defp schema_and_data(kind, n) do
    schemas = %{
      items: %{items: @integer},
      prefixItems: %{prefixItems: List.duplicate(@integer, n)},
      properties: %{properties: Map.new(1..n, &{"key#{&1}", @integer})},
      additionalProperties: %{additionalProperties: @integer},
      additionalProperties_false: %{additionalProperties: false},
      patternProperties: %{patternProperties: %{"^key" => @integer}},
      propertyNames: %{propertyNames: %{maxLength: 2}},
      draft7_items: %{"$schema" => @draft7, items: @integer},
      draft7_items_array: %{"$schema" => @draft7, items: List.duplicate(@integer, n)},
      draft7_additionalItems: %{"$schema" => @draft7, items: [], additionalItems: @integer}
    }

    data =
      if kind in @list_kinds do
        Enum.map(1..n, &"item#{&1}")
      else
        Map.new(1..n, &{"key#{&1}", "value#{&1}"})
      end

    {Map.fetch!(schemas, kind), data}
  end

  defp copied_size(kind, n) do
    {schema, data} = schema_and_data(kind, n)
    assert {:error, err} = JSV.validate(data, JSV.build!(schema))
    byte_size(:erlang.term_to_binary(err))
  end

  for kind <- @list_kinds ++ @map_kinds do
    test "copied error grows linearly with the number of invalid children: #{kind}" do
      assert copied_size(unquote(kind), 400) < 6 * copied_size(unquote(kind), 100)
    end
  end
end
