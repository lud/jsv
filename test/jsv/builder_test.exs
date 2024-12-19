defmodule JSV.BuilderTest do
  alias JSV.Builder
  alias JSV.Schema
  alias JSV.Test.TestResolver
  use ExUnit.Case, async: true

  IO.warn("TODO build atom schema tests")

  test "building with a schema struct" do
    raw_schema = %{"properties" => %{"name" => %{"type" => "string"}}}
    struct_schema = %Schema{properties: %{name: %Schema{type: :string}}}
    shrink_schema(%Schema{properties: %{name: %Schema{type: :string}}})

    builder = Builder.new(resolver: TestResolver, default_meta: JSV.default_meta())

    built_raw = Builder.build(builder, raw_schema)
  end

  test "the builder does not fetch schemas on new()" do
    defmodule BadResolver do
    end

    raw_schema = %{"properties" => %{"name" => %{"type" => "string"}}}
    builder = Builder.new(resolver: BadResolver, default_meta: JSV.default_meta())

    # no error has been raised
  end

  def shrink_schema(schema) when is_struct(schema) when is_map(schema) do
    schema
    |> Map.filter(fn
      {_, nil} -> false
      {:__struct__, _} -> false
      _ -> true
    end)
    |> Map.new(fn {k, v} -> {k, shrink_schema(v)} end)
  end

  def shrink_schema(list) when is_list(list) do
    Enum.map(list, &shrink_schema/1)
  end

  def shrink_schema(other) do
    other
  end
end
