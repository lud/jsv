# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.SchemaTest do
  alias JSV.Schema
  alias JSV.Schema.Composer
  use ExUnit.Case, async: true

  doctest JSV.Schema

  defmodule TestCustomStruct do
    defstruct [:properties, :foo, :required]
  end

  describe "merge/2" do
    test "merge accepts nil as base and returns a Schema struct" do
      result = Schema.merge(nil, %{type: :string})
      assert %Schema{type: :string} = result
    end

    test "merge accepts a map as base and keeps it as a map" do
      base = %{foo: "bar"}
      assert %{foo: "bar", type: :string} = result = Schema.merge(base, %{type: :string})
      refute is_struct(result)
    end

    test "merge accepts a Schema struct as base" do
      base = %Schema{description: "test"}
      result = Schema.merge(base, %{type: :string})
      assert %Schema{description: "test", type: :string} = result
    end

    test "merge fails if another struct is passed and doesn't have the keys" do
      base = %TestCustomStruct{foo: "bar"}

      # the struct accept properties

      assert %TestCustomStruct{foo: "bar", properties: %{a: %{type: :integer}}} =
               Schema.merge(base, properties: %{a: %{type: :integer}})

      # the struct does not have a :type key

      assert_raise KeyError, ~r/does not accept key :type/, fn ->
        Schema.merge(base, %{type: :string})
      end
    end

    test "merge does not add unknown keys in a Schema struct" do
      assert_raise KeyError, ~r/does not accept key :foo/, fn ->
        Schema.merge(%Schema{}, %{foo: :bar})
      end
    end

    test "merge accepts a keyword list as base and returns a Schema struct" do
      base = [description: "some description"]
      result = Schema.merge(base, %{type: :string})
      assert %Schema{description: "some description", type: :string} = result
      assert is_struct(result)
    end

    # Same tests but with a defcompose generated helper

    test "compose accepts nil as base and returns a Schema struct" do
      result = Composer.string(nil)
      assert %Schema{type: :string} = result
    end

    test "compose accepts a map as base and keeps it as a map" do
      base = %{foo: "bar"}
      assert %{foo: "bar", type: :string} = result = Composer.string(base)
      refute is_struct(result)
    end

    test "compose accepts a Schema struct as base" do
      base = %Schema{description: "test"}
      result = Composer.string(base)
      assert %Schema{description: "test", type: :string} = result
    end

    test "compose fails if another struct is passed and doesn't have the keys" do
      base = %TestCustomStruct{foo: "bar"}

      # the struct accept properties

      assert %TestCustomStruct{foo: "bar", properties: %{a: %{type: :integer}}} =
               Schema.Composer.properties(base, a: %{type: :integer})

      # the struct does not have a :type key

      assert_raise KeyError, ~r/does not accept key :type/, fn ->
        Composer.string(base)
      end
    end

    test "compose accepts a keyword list as base and returns a Schema struct" do
      base = [description: "some description"]
      result = Composer.string(base)
      assert %Schema{description: "some description", type: :string} = result
      assert is_struct(result)
    end
  end

  describe "xcast/1" do
    test "single atom module is stored as a string" do
      assert %{"x-jsv-cast": "Elixir.MyApp.Cast"} = Schema.xcast(MyApp.Cast)
    end

    test "single string module is stored as-is" do
      assert %{"x-jsv-cast": "Elixir.MyApp.Cast"} = Schema.xcast("Elixir.MyApp.Cast")
    end

    test "list with atom module and atom tag normalizes to list of strings" do
      assert %{"x-jsv-cast": [["Elixir.MyApp.Cast", "a_cast_function"]]} =
               Schema.xcast([MyApp.Cast, :a_cast_function])
    end

    test "list with erlang module atom and string tag" do
      assert %{"x-jsv-cast": [["some_erlang_module", "custom_tag"]]} =
               Schema.xcast([:some_erlang_module, "custom_tag"])
    end
  end

  describe "xcast/2" do
    test "appending a second atom module to an atom-created schema" do
      assert %{"x-jsv-cast": ["Elixir.MyApp.Foo", "Elixir.MyApp.Cast"]} =
               %{} |> Schema.xcast(MyApp.Foo) |> Schema.xcast(MyApp.Cast)
    end

    test "appending a list caster to a string base" do
      assert %{"x-jsv-cast": ["Elixir.MyApp.Foo", ["Elixir.MyApp.Cast", "some_function", %{"123" => "foo"}]]} =
               %{} |> Schema.xcast(MyApp.Foo) |> Schema.xcast([MyApp.Cast, "some_function", %{123 => :foo}])
    end

    test "binary key x-jsv-cast is converted to atom key" do
      assert %{"x-jsv-cast": ["Elixir.MyApp.Foo", "Elixir.MyApp.Cast"]} =
               Schema.xcast(%{"x-jsv-cast" => "Elixir.MyApp.Foo"}, MyApp.Cast)
    end

    test "appending to an existing list base" do
      base = %{"x-jsv-cast": ["Elixir.A", "Elixir.B"]}

      assert %{"x-jsv-cast": ["Elixir.A", "Elixir.B", "Elixir.MyApp.C"]} =
               Schema.xcast(base, MyApp.C)
    end

    test "appending a list caster to an existing list base" do
      base = %{"x-jsv-cast": ["Elixir.A"]}

      assert %{"x-jsv-cast": ["Elixir.A", ["Elixir.MyApp.B", "tag"]]} =
               Schema.xcast(base, [MyApp.B, "tag"])
    end

    test "raises on mixed atom and binary x-jsv-cast keys" do
      bad_schema = %{:"x-jsv-cast" => "Elixir.A", "x-jsv-cast" => "Elixir.B"}

      assert_raise ArgumentError, ~r/mixing/, fn ->
        Schema.xcast(bad_schema, MyApp.C)
      end
    end

    test "preserves other schema keys" do
      base = %{type: :object, properties: %{name: %{type: :string}}}
      result = Schema.xcast(base, MyApp.Cast)
      assert %{type: :object, properties: %{name: %{type: :string}}, "x-jsv-cast": "Elixir.MyApp.Cast"} = result
    end

    test "works with JSV.Schema struct as base - single caster" do
      base = %Schema{type: :object, "x-jsv-cast": nil}
      # Since Schema struct always has the key (as nil), xcast/2 sees the nil
      # value. We set it explicitly to confirm behavior matches plain maps
      # without the key by using Map.delete.
      base = Map.delete(base, :"x-jsv-cast")
      result = Schema.xcast(base, MyApp.Cast)
      assert %{type: :object, "x-jsv-cast": "Elixir.MyApp.Cast"} = result
    end

    test "works with JSV.Schema struct that already has x-jsv-cast" do
      base = %Schema{type: :string, "x-jsv-cast": "Elixir.MyApp.Existing"}
      result = Schema.xcast(base, MyApp.Another)
      assert %Schema{type: :string, "x-jsv-cast": ["Elixir.MyApp.Existing", "Elixir.MyApp.Another"]} = result
    end

    test "works with JSV.Schema struct that has x-jsv-cast as list" do
      base = %Schema{type: :string, "x-jsv-cast": ["Elixir.MyApp.First"]}
      result = Schema.xcast(base, MyApp.Second)
      assert %Schema{type: :string, "x-jsv-cast": ["Elixir.MyApp.First", "Elixir.MyApp.Second"]} = result
    end

    test "works with JSV.Schema struct where x-jsv-cast is nil (not set)" do
      # x-jsv-cast is nil in the struct, should be treated as absent
      base = %Schema{type: :object}

      result = Schema.xcast(base, MyApp.Cast)
      assert %Schema{type: :object, "x-jsv-cast": "Elixir.MyApp.Cast"} = result

      result = Schema.xcast(base, [MyApp.Cast, "foo"])
      assert %Schema{type: :object, "x-jsv-cast": [["Elixir.MyApp.Cast", "foo"]]} = result
    end

    test "works with JSV.Schema struct as base - multiple casters" do
      base = %Schema{type: :object}

      result =
        base
        |> Schema.xcast(MyApp.Foo)
        |> Schema.xcast([MyApp.Bar, "tag"])

      assert %{type: :object, "x-jsv-cast": ["Elixir.MyApp.Foo", ["Elixir.MyApp.Bar", "tag"]]} = result
    end
  end
end
