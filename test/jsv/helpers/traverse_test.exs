defmodule JSV.Helpers.TraverseTest do
  alias JSV.Helpers.Traverse
  use ExUnit.Case, async: true

  doctest JSV.Helpers.Traverse

  describe "postwalk traversal" do
    test "sees children before" do
      # * postwalk is called on the children before the parents.
      # * whenever we see the integer value we increment it
      # * when the parent is called, it should be called with the incremented
      #   value
      #
      # Here we match directly of what is expected.
      data = %{"parent" => %{"child" => 0}}

      assert %{"parent" => %{"child" => 3}} =
               Traverse.postwalk(data, fn
                 {:val, 0} -> 1
                 {:key, k} -> k
                 {:val, %{"child" => 1}} -> %{"child" => 2}
                 {:val, %{"parent" => %{"child" => 2}}} -> %{"parent" => %{"child" => 3}}
               end)
    end

    test "supports lists" do
      data = [1, 2, [3, 4]]

      assert [10, 20, [30, 40]] =
               Traverse.postwalk(data, fn
                 {:val, n} when is_integer(n) -> n * 10
                 {:val, [30, 40] = v} -> v
                 {:val, [10, 20, [30, 40]] = v} -> v
               end)
    end

    test "supports tuples" do
      data = {1, 2, {3, 4}}

      assert {10, 20, {30, 40}} =
               Traverse.postwalk(data, fn
                 {:val, n} when is_integer(n) -> n * 10
                 {:val, {30, 40} = v} -> v
                 {:val, {10, 20, {30, 40}} = v} -> v
               end)
    end

    defmodule SomeStruct do
      defstruct enum: []
    end

    test "special handling of structs" do
      data = %SomeStruct{enum: [1, 2, 3]}

      # By default, sub values of struct are not called
      assert %SomeStruct{enum: [1, 2, 3]} ==
               Traverse.postwalk(data, fn
                 # This will not be called
                 {:val, _} -> raise "called with val"
                 # And so the struct in unchanged on post since we do not call the continuation
                 {:struct, %SomeStruct{enum: [1, 2, 3]} = s, _} -> s
               end)

      # But the tool provides a continuation that will traverse the given structure

      assert %{enum: [10, 20, 30]} ==
               Traverse.postwalk(data, fn
                 # This will now be called
                 {:val, n} when is_integer(n) ->
                   n * 10

                 # The list is still passed post-traversal
                 {:val, [10, 20, 30] = v} ->
                   v

                 # Keys are passed since we call Map.from_struct/1
                 {:key, :enum} ->
                   :enum

                 # The map-from-struct itself should not be passed as it represents the struct
                 {:val, %{enum: _}} ->
                   raise "should not be called"

                 # But it is not called before the struct is given to the
                 # callback.
                 {:struct, %SomeStruct{enum: [1, 2, 3]} = s, cont} ->
                   {map, nil} = cont.(Map.from_struct(s), nil)
                   map
               end)
    end

    test "keys are not traversed" do
      data = %{{1, 2} => "position"}

      assert %{{1, 2} => "position-2"} =
               Traverse.postwalk(data, fn
                 {:val, "position"} -> "position-1"
                 {:key, {1, 2} = k} -> k
                 {:val, %{{1, 2} => "position-1"}} -> %{{1, 2} => "position-2"}
               end)
    end

    test "catchall clause can just return the second tuple element" do
      original_data = %{
        :a => [~c"hello", {1, 3}],
        :x => %Inspect.Opts{},
        %{x: :y, z: %{z: 1}} => %{nested: [a: 1, b: {:c}] ++ [{}, self()]}
      }

      traversed_data = Traverse.postwalk(original_data, &elem(&1, 1))

      assert original_data == traversed_data
    end
  end
end
