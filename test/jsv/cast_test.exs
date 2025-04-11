defmodule JSV.CastTest do
  alias JSV.Schema
  require JSV
  use ExUnit.Case, async: true

  describe "using the defschemacast macro" do
    test "can cast raw data to arbitrary data" do
      defmodule ExpectsString do
        def __jsv__("some_arg", "hello") do
          {:ok, :some_cast_value}
        end
      end

      schema = %{
        type: :string,
        "jsv-cast": [to_string(ExpectsString), "some_arg"]
      }

      root = JSV.build!(schema)

      # The cast is called after validation so it should not be called
      assert {:ok, :some_cast_value} = JSV.validate("hello", root)
    end

    test "not called when data is invalid" do
      defmodule ExpectsInteger do
        def __jsv__(_, _) do
          raise "will not be called"
        end
      end

      schema = %{
        type: :integer,
        "jsv-cast": [to_string(ExpectsInteger), "some_arg"]
      }

      root = JSV.build!(schema)

      assert {:error, _validation_error} = JSV.validate("hello", root)
    end

    test "can return an error" do
      defmodule ReturnsError do
        def __jsv__("some_arg", "hello") do
          # returns a JSON-incompatible term. It's not a problem since the
          # format error callback will be called.
          {:error, {:expected, "goodbye", "hello", :in, self()}}
        end

        def format_error("some_arg", {:expected, "goodbye", "hello", :in, pid}, "hello") when pid == self() do
          {:custom_kind, "this is an err msg"}
        end
      end

      schema = %{
        type: :string,
        "jsv-cast": [to_string(ReturnsError), "some_arg"]
      }

      root = JSV.build!(schema)

      assert {:error, validation_error} = JSV.validate("hello", root)

      # The error is normalizable
      validation_error |> dbg(limit: :infinity)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "this is an err msg", kind: :custom_kind}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error) |> dbg(limit: :infinity)
    end
  end

  IO.warn("TODO with rescue block")
  IO.warn("TODO with custom tag")
  IO.warn("TODO with atom name of fun")
  IO.warn("TODO with atom name of fun and custom tag")
  IO.warn("TODO with guard")
  IO.warn("TODO with custom tag with guard")

  defmodule CastExample do
    import JSV

    # with call
    defschemacast with_do_block(data) do
      if is_binary(data) do
        {:ok, String.upcase(data)}
      else
        {:error, :expected_string}
      end
    end

    defschemacast with_rescue_block(data) do
      if is_binary(data) do
        upper =
          data
          |> String.to_existing_atom()
          |> Atom.to_string()
          |> String.upcase()

        {:ok, upper}
      else
        {:error, :expected_string}
      end
    rescue
      ArgumentError -> {:error, :unknown_existing_atom}
    end
  end

  describe "macros used in CastExample module" do
    # All functions in the example module expect a string and will return that
    # string to uppercase.
    #
    # The wrapping schema does not validate anything.
    defp call_with(caster, data) when is_binary(caster) do
      schema = %{"jsv-cast": [to_string(CastExample), caster]}
      root = JSV.build!(schema)
      JSV.validate(data, root)
    end

    defp cast_ok(caster, data) do
      assert {:ok, result} = call_with(caster, data)
      result
    end

    defp cast_err(caster, data) do
      assert {:error,
              %JSV.ValidationError{
                errors: [
                  %JSV.Validator.Error{
                    kind: :"jsv-cast",
                    data: _,
                    args: [module: JSV.CastTest.CastExample, reason: reason, arg: ^caster],
                    formatter: JSV.Vocabulary.Cast
                  }
                ]
              }} = call_with(caster, data)

      reason
    end

    test "deschemacast/2 using a :do block" do
      # The /0 arity function returns the schema pointer
      assert [to_string(CastExample), "with_do_block"] == CastExample.with_do_block()

      # The /1 arity function is defined and corresponds to the user code
      assert {:ok, "HELLO"} = CastExample.with_do_block("hello")

      # It works as a caster
      assert "HELLO" = cast_ok("with_do_block", "hello")
      assert :expected_string == cast_err("with_do_block", 1234)
    end

    test "deschemacast/2 using a rescue block" do
      # The /0 arity function returns the schema pointer
      assert [to_string(CastExample), "with_rescue_block"] == CastExample.with_rescue_block()

      # The /1 arity function is defined and corresponds to the user code
      assert {:ok, "PERSISTENT_TERM"} = CastExample.with_rescue_block("persistent_term")

      # It works as a caster
      assert "PERSISTENT_TERM" = cast_ok("with_rescue_block", "persistent_term")
      assert :unknown_existing_atom == cast_err("with_rescue_block", "heeeeeeeeello")
      assert :expected_string == cast_err("with_rescue_block", 1234)
    end
  end
end
