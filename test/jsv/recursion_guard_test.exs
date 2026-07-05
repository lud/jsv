# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.RecursionGuardTest do
  use ExUnit.Case, async: true

  # Schemas whose refs re-enter the same schema node against the same data
  # would recurse forever without the guard in JSV.Validator.validate_ref/4,
  # so every validation here runs in a task with a timeout: a regression
  # fails the test instead of hanging the suite.

  @timeout 5_000

  defp validate_halting(data, root) do
    task = Task.async(fn -> JSV.validate(data, root) end)

    case Task.yield(task, @timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> flunk("validation did not terminate within #{@timeout}ms")
    end
  end

  defp build!(schema) do
    JSV.build!(schema, atoms: false)
  end

  describe "no-progress ref cycles" do
    test "self-referential $ref validates successfully" do
      # The cycle states no constraint over the data, so following the
      # open-world semantics the data is valid.
      root =
        build!(%{
          "$defs" => %{"a" => %{"allOf" => [%{"$ref" => "#/$defs/a"}]}},
          "$ref" => "#/$defs/a"
        })

      assert {:ok, 123} = validate_halting(123, root)
    end

    test "self-referential $dynamicRef validates successfully" do
      root =
        build!(%{
          "$id" => "http://recursion-guard.test/dynamic",
          "$dynamicAnchor" => "node",
          "allOf" => [%{"$dynamicRef" => "#node"}]
        })

      assert {:ok, 123} = validate_halting(123, root)
    end

    test "$dynamicRef resolving through the static-anchor fallback" do
      # The first hop of "$dynamicRef": "#n" finds no dynamic anchor in scope
      # and falls back to the static anchor "n" (schema s). Following s enters
      # document b, whose $dynamicAnchor "n" makes the re-entering hop resolve
      # to a different target than the first one. The run is still an infinite
      # loop (resolution is stable from the first repetition onward), so the
      # cut applies.
      root =
        build!(%{
          "$id" => "http://recursion-guard.test/r",
          "$defs" => %{
            "s" => %{"$anchor" => "n", "$ref" => "http://recursion-guard.test/b"},
            "b" => %{
              "$id" => "http://recursion-guard.test/b",
              "$dynamicAnchor" => "n",
              "allOf" => [%{"$ref" => "http://recursion-guard.test/r"}]
            }
          },
          "allOf" => [%{"$dynamicRef" => "#n"}]
        })

      assert {:ok, 123} = validate_halting(123, root)
    end

    test "mutually referencing schemas validate successfully" do
      root =
        build!(%{
          "$defs" => %{
            "alice" => %{"allOf" => [%{"$ref" => "#/$defs/bob"}]},
            "bob" => %{"allOf" => [%{"$ref" => "#/$defs/alice"}]}
          },
          "$ref" => "#/$defs/alice"
        })

      assert {:ok, "hello"} = validate_halting("hello", root)
    end
  end

  describe "constraints on cycle members are enforced" do
    # Only the re-entering ref hop is cut, so validation must still apply
    # the constraints attached to every schema node of the loop. Each
    # failing datum below violates exactly one node's constraint, proving
    # that this node was evaluated.

    defp three_node_loop do
      build!(%{
        "$defs" => %{
          "a" => %{"minimum" => 3, "allOf" => [%{"$ref" => "#/$defs/b"}]},
          "b" => %{"maximum" => 100, "allOf" => [%{"$ref" => "#/$defs/c"}]},
          "c" => %{"multipleOf" => 5, "allOf" => [%{"$ref" => "#/$defs/a"}]}
        },
        "$ref" => "#/$defs/a"
      })
    end

    test "A→B→C→A loop accepts data satisfying all nodes" do
      assert {:ok, 10} = validate_halting(10, three_node_loop())
    end

    test "A→B→C→A loop enforces each node's constraint" do
      root = three_node_loop()

      # violates a's minimum only
      assert {:error, _} = validate_halting(0, root)
      # violates b's maximum only
      assert {:error, _} = validate_halting(105, root)
      # violates c's multipleOf only
      assert {:error, _} = validate_halting(7, root)
    end

    defp multi_cycle_graph do
      # Two interleaved cycles: A→B→C→A and B→D→B.
      build!(%{
        "$defs" => %{
          "a" => %{"minimum" => 0, "allOf" => [%{"$ref" => "#/$defs/b"}]},
          "b" => %{
            "maximum" => 100,
            "allOf" => [%{"$ref" => "#/$defs/c"}, %{"$ref" => "#/$defs/d"}]
          },
          "c" => %{"multipleOf" => 2, "allOf" => [%{"$ref" => "#/$defs/a"}]},
          "d" => %{"multipleOf" => 3, "allOf" => [%{"$ref" => "#/$defs/b"}]}
        },
        "$ref" => "#/$defs/a"
      })
    end

    test "multi-cycle graph accepts data satisfying all nodes" do
      assert {:ok, 6} = validate_halting(6, multi_cycle_graph())
    end

    test "multi-cycle graph enforces each node's constraint" do
      root = multi_cycle_graph()

      # violates a's minimum only
      assert {:error, _} = validate_halting(-6, root)
      # violates b's maximum only
      assert {:error, _} = validate_halting(102, root)
      # violates c's multipleOf only
      assert {:error, _} = validate_halting(3, root)
      # violates d's multipleOf only
      assert {:error, _} = validate_halting(4, root)
    end
  end

  describe "legitimate re-evaluation is not cut" do
    test "sibling refs to the same schema at the same data location" do
      # The second sibling hop must be evaluated: refs are only cut while
      # already on the evaluation stack, not once they have been seen.
      root =
        build!(%{
          "$defs" => %{"int" => %{"type" => "integer"}},
          "allOf" => [%{"$ref" => "#/$defs/int"}, %{"$ref" => "#/$defs/int"}]
        })

      assert {:ok, 1} = validate_halting(1, root)
      assert {:error, _} = validate_halting("nope", root)
    end

    test "identical subtrees at different data paths are evaluated separately" do
      # The same subtree value appears under /a and /b. Seen refs are reset on
      # descent and never merged back, so the hop under /b must be evaluated
      # even though an equal {ref, data} pair was already evaluated under /a.
      root =
        build!(%{
          "$defs" => %{
            "node" => %{
              "properties" => %{
                "a" => %{"$ref" => "#/$defs/node"},
                "b" => %{"$ref" => "#/$defs/node"},
                "n" => %{"type" => "integer"}
              }
            }
          },
          "$ref" => "#/$defs/node"
        })

      x = %{"n" => 1}
      assert {:ok, _} = validate_halting(%{"a" => x, "b" => x}, root)
      assert {:error, _} = validate_halting(%{"a" => x, "b" => %{"n" => "bad"}}, root)
    end

    test "recursive schema over nested data descends normally" do
      root =
        build!(%{
          "properties" => %{
            "child" => %{"$ref" => "#"},
            "n" => %{"type" => "integer"}
          }
        })

      assert {:ok, _} = validate_halting(%{"child" => %{"child" => %{"n" => 1}}}, root)
      assert {:error, _} = validate_halting(%{"child" => %{"child" => %{"n" => "x"}}}, root)
    end

    test "self-referential propertyNames still applies string constraints" do
      # propertyNames validates the object keys without changing the data
      # path. The guard keys on the data itself, so the ref re-entry with a
      # key string is a fresh evaluation and minLength applies.
      root =
        build!(%{
          "$defs" => %{
            "a" => %{
              "minLength" => 3,
              "propertyNames" => %{"$ref" => "#/$defs/a"}
            }
          },
          "$ref" => "#/$defs/a"
        })

      assert {:ok, _} = validate_halting(%{"abcd" => 1}, root)
      assert {:error, _} = validate_halting(%{"ab" => 1}, root)
    end
  end
end
