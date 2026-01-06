defmodule JSV.NormalizerTest do
  alias JSV.Resolver.Internal
  alias JSV.Schema
  use ExUnit.Case, async: true

  doctest JSV.Normalizer

  describe "normalize" do
    test "remove all atoms from map" do
      # handles maps with atom keys
      assert %{"hello" => "world"} == Schema.normalize(%{hello: "world"})

      # handles maps with numeric keys
      assert %{"1" => "one", "-0.0" => "zero"} == Schema.normalize(%{1 => "one", -0.0 => "zero"})

      # handles maps with atom values
      assert %{"hello" => "world"} == Schema.normalize(%{hello: :world})

      # keeps booleans and nil as values but not keys
      assert %{"true" => true} == Schema.normalize(%{true: true})
      assert %{"false" => false} == Schema.normalize(%{false: false})
      assert %{"nil" => nil} == Schema.normalize(%{nil: nil})

      # keeps basic types
      assert %{"i" => 1, "f" => 2.3, "l" => [4]} == Schema.normalize(%{i: 1, f: 2.3, l: [4]})
    end

    test "removes all atoms and nil values from Schema struct" do
      # handles structs with a special treatment for the schema struct, it removes
      # all nil values.

      assert %{"title" => "stuff"} == Schema.normalize(%Schema{title: "stuff"})

      assert %{"anyOf" => [%{"properties" => %{"foo" => 1}}]} ==
               Schema.normalize(%Schema{anyOf: [%Schema{properties: %{foo: 1}}]})
    end

    defmodule MyStruct do
      defstruct a: nil, b: nil
    end

    test "calls the normalizer for other structs" do
      defimpl JSV.Normalizer.Normalize, for: MyStruct do
        @impl true
        def normalize(s) do
          send(self(), {:called_protocol, s.a})
          %{"some_other_key" => s.a, "b" => s.b}
        end
      end

      # It will be called on the struct
      assert %{"some_other_key" => "hello", "b" => nil} == Schema.normalize(%MyStruct{a: "hello"})
      assert_receive {:called_protocol, "hello"}

      # It will be called on both structs, and should be called on the parent
      # struct first, despite being postwalk
      assert %{"some_other_key" => "parent", "b" => %{"some_other_key" => "child", "b" => nil}} ==
               Schema.normalize(%MyStruct{a: "parent", b: %MyStruct{a: "child"}})

      assert "parent" ==
               (receive do
                  {:called_protocol, who} -> who
                end)

      assert "child" ==
               (receive do
                  {:called_protocol, who} -> who
                end)
    end

    test "incompatible values: tuple keys" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{{:a, :b} => "value"})
      end
    end

    test "incompatible values: tuple values" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{key: {:a, :b}})
      end
    end

    test "incompatible values: pid keys" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{self() => "value"})
      end
    end

    test "incompatible values: pid values" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{key: self()})
      end
    end

    test "incompatible values: ref keys" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{make_ref() => "value"})
      end
    end

    test "incompatible values: ref values" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{key: make_ref()})
      end
    end

    test "converts modules that export json_schema/0 to refs" do
      defmodule ExportsSchema do
        @spec schema :: no_return()
        def schema do
          raise "will not be called"
        end
      end

      assert %{"$ref" => Internal.module_to_uri(ExportsSchema)} == Schema.normalize(ExportsSchema)
    end

    test "converts Elixir modules that do not export json_schema/0 to string" do
      # This is enforced because we expect the atom to be a valid module
      defmodule DoesNotExportSchema do
      end

      assert to_string(DoesNotExportSchema) == Schema.normalize(DoesNotExportSchema)
    end

    test "converts Erlang modules that do not export json_schema/0 to string" do
      # This is not an Elixir module, so we cannot know if it's a custom type, format, etc.
      defmodule unquote(:test_schema_module_to_ref) do
      end

      # So it's just stringified
      assert "test_schema_module_to_ref" == Schema.normalize(:test_schema_module_to_ref)
    end

    test "converts Erlang modules that export schema_schema/0 to $ref" do
      # This is not an Elixir module, so we cannot know if it's a custom type, format, etc.
      defmodule unquote(:test_schema_module_to_ref_with_schema) do
        @spec schema :: no_return()
        def schema do
          raise "will not be called"
        end
      end

      # Since we can find the function it's a $ref
      assert %{"$ref" => Internal.module_to_uri(:test_schema_module_to_ref_with_schema)} ==
               Schema.normalize(:test_schema_module_to_ref_with_schema)
    end

    defmodule NormalizeTo do
      defstruct [:value]
    end

    defimpl JSV.Normalizer.Normalize, for: NormalizeTo do
      def normalize(%{value: value}) do
        value
      end
    end

    test "can replace struct with non-map values" do
      assert "hello" = Schema.normalize(%NormalizeTo{value: "hello"})
      assert [1, 2, "hello"] = Schema.normalize(%NormalizeTo{value: [1, 2, :hello]})

      assert %{"some_key" => "some_val"} =
               Schema.normalize(%NormalizeTo{
                 value: %{some_key: %NormalizeTo{value: :some_val}}
               })

      # It is not supported to use struct as keys (yet?) because maps are not
      # re-normalized when the traverse function operates on a {:struct, _, _}
      # tuple. When the normalizer implementation for a struct returns a map,
      # the keys must be correctly encoded.
      assert_raise ArgumentError, ~r"invalid key", fn ->
        Schema.normalize(%{%NormalizeTo{value: :some_key} => %NormalizeTo{value: :some_val}})
      end

      assert [1, 2, %{"k" => [%{"k2" => "sub"}]}] =
               Schema.normalize([
                 %NormalizeTo{value: 1},
                 %NormalizeTo{value: 2},
                 %NormalizeTo{
                   value: %{
                     k: %NormalizeTo{
                       value: [
                         %NormalizeTo{
                           value: %{
                             k2: %NormalizeTo{value: :sub}
                           }
                         }
                       ]
                     }
                   }
                 }
               ])

      # Tuples are not supported by the Schema normalizer but the general
      # normalizer does accept them
      assert_raise ArgumentError, ~r"invalid value in JSON data", fn ->
        Schema.normalize(%NormalizeTo{value: {1, 2, :hello}})
      end

      # Returning a struct is invalid
      assert_raise ArgumentError, ~r"continuation function does not accept structs", fn ->
        Schema.normalize(%NormalizeTo{value: %MyStruct{}})
      end
    end
  end
end
