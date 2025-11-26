# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.CastTest do
  alias JSV.Resolver.Internal
  use JSV.Schema
  use ExUnit.Case, async: true

  describe "using the defcast macro" do
    test "can cast raw data to arbitrary data" do
      defmodule ExpectsString do
        def __jsv__("some_arg", "hello") do
          {:ok, :some_cast_value}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [to_string(ExpectsString), "some_arg"]
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
        "x-jsv-cast": [to_string(ExpectsInteger), "some_arg"]
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
        "x-jsv-cast": [to_string(ReturnsError), "some_arg"]
      }

      root = JSV.build!(schema)
      assert {:error, validation_error} = JSV.validate("hello", root)
      # The error is normalizable
      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "this is an err msg", kind: :custom_kind}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error, keys: :atoms)
    end

    test "does not crash on unexported functions" do
      schema = %{
        type: :string,
        "x-jsv-cast": ["Elixir.System", "stop"]
      }

      root = JSV.build!(schema)
      assert {:error, validation_error} = JSV.validate("hello", root)
      # The error is normalizable
      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "invalid cast", kind: :cast}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error, keys: :atoms)
    end

    test "only handles unexported functions on __jsv__ call" do
      defmodule NestedUnexportedFunction do
        def __jsv__("some_tag", _) do
          UnknownModule.a_function()
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [to_string(NestedUnexportedFunction), "some_tag"]
      }

      root = JSV.build!(schema)
      # Since the error is not on the __jsv__ call it should rise
      assert_raise UndefinedFunctionError, ~r/UnknownModule.a_function.*is undefined/, fn ->
        JSV.validate("hello", root)
      end
    end

    test "does not crash on function clause error" do
      defmodule DoesNotKnowTag do
        def __jsv__("some_tag", _) do
          {:ok, :whatever}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [to_string(DoesNotKnowTag), "ANOTHER TAG"]
      }

      root = JSV.build!(schema)
      assert {:error, validation_error} = JSV.validate("hello", root)
      # The error is normalizable
      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "invalid cast", kind: :cast}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error, keys: :atoms)
    end

    test "only handles function clause errors on __jsv__ call" do
      defmodule NestedFunctionClauseError do
        def __jsv__("some_tag", "hello") do
          local_fun(1234)
        end

        defp local_fun(:x) do
          {:ok, "hello"}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [to_string(NestedFunctionClauseError), "some_tag"]
      }

      root = JSV.build!(schema)
      # Since the error is not on the __jsv__ call it should rise
      assert_raise FunctionClauseError, ~r/no function clause matching in.*NestedFunctionClauseError.local_fun/, fn ->
        JSV.validate("hello", root)
      end
    end
  end

  defmodule CastExample do
    use JSV.Schema

    defp to_upper_if_string(data) do
      if is_binary(data) do
        {:ok, String.upcase(data)}
      else
        {:error, {:expected_string, data}}
      end
    end

    # with call
    defcast with_do_block(data) do
      to_upper_if_string(data)
    end

    defcast with_rescue_block(data) do
      result = to_upper_if_string(data)

      if is_binary(data) do
        String.to_existing_atom(data)
      end

      result
    rescue
      ArgumentError -> {:error, :unknown_existing_atom}
    end

    defcast ?t, with_custom_tag_int(data) do
      to_upper_if_string(data)
    end

    defcast "some tag", with_custom_tag_str(data) do
      to_upper_if_string(data)
    end

    defcast :some_local_fun

    def some_local_fun(data) do
      to_upper_if_string(data)
    end

    def some_local_fun do
      [to_string(__MODULE__), "some_local_fun"]
    end

    defcast "some local tag", :to_upper_if_string

    def format_error(tag, {:expected_string, data}, data) do
      "expected a string but got: #{inspect(data)} in #{inspect(tag)}"
    end

    def format_error("with_rescue_block", :unknown_existing_atom, string) do
      "not an existing atom representation: #{inspect(string)}"
    end
  end

  describe "macros used in CastExample module" do
    # All functions in the example module expect a string and will return that
    # string to uppercase.
    #
    # The wrapping schema does not validate anything.
    defp call_with(caster, data) when is_binary(caster) when is_integer(caster) do
      schema = %{"x-jsv-cast": [to_string(CastExample), caster]}
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
                    kind: :"x-jsv-cast",
                    data: _,
                    args: [module: JSV.CastTest.CastExample, reason: reason, arg: ^caster],
                    formatter: JSV.Vocabulary.Cast
                  }
                ]
              } = e} = call_with(caster, data)

      # Ensure we implement the format error examples for documentation
      assert %{} = JSV.normalize_error(e)
      reason
    end

    defp try_caster(fun, tag) do
      _ = :some_existing_atom
      valid_data = "some_existing_atom"
      valid_cast = "SOME_EXISTING_ATOM"
      invalid_data = 123_456

      if fun != nil do
        # The /0 arity function returns the schema pointer
        assert [to_string(CastExample), tag] == apply(CastExample, fun, [])
        # The /1 arity function is defined and corresponds to the user code
        assert {:ok, ^valid_cast} = apply(CastExample, fun, [valid_data])
      end

      # # It works as a caster
      assert ^valid_cast = cast_ok(?t, valid_data)
      assert {:expected_string, invalid_data} == cast_err(tag, invalid_data)
    end

    test "defcast using a :do block" do
      try_caster(:with_do_block, "with_do_block")
    end

    test "defcast using a rescue block" do
      try_caster(:with_rescue_block, "with_rescue_block")
      assert :unknown_existing_atom == cast_err("with_rescue_block", "not an existing atom")
    end

    test "defcast using a custom tag (integer)" do
      try_caster(:with_custom_tag_int, ?t)
    end

    test "defcast using a custom tag (string)" do
      try_caster(:with_custom_tag_str, "some tag")
    end

    test "some local fun" do
      try_caster(nil, "some_local_fun")
    end

    test "some local fun with custom tag" do
      try_caster(nil, "some local tag")
    end

    test "guards are not supported" do
      assert_raise ArgumentError, ~r/defcast does not support guards/, fn ->
        defmodule UsesGuard do
          use JSV.Schema

          defcast with_guard(data) when data > 10 when data != "hello" do
            {:ok, nil}
          end
        end
      end
    end

    test "bad calls" do
      assert_raise ArgumentError, ~r/invalid defcast/, fn ->
        defmodule UsesHeadFun do
          use JSV.Schema
          defcast with_head_fun(data)
        end
      end

      assert_raise ArgumentError, ~r/invalid defcast signature/, fn ->
        defmodule UsesHeadFun do
          use JSV.Schema

          defcast with_args(too, much, args) do
            {:ok, too}
          end
        end
      end

      assert_raise ArgumentError, ~r/invalid defcast/, fn ->
        defmodule UsesHeadFun do
          use JSV.Schema
          defcast :aaa, 1234
        end
      end

      assert_raise ArgumentError, ~r/invalid defcast/, fn ->
        defmodule UsesHeadFun do
          use JSV.Schema

          defcast :tag, hello(data) do
            {:ok, data}
          end
        end
      end
    end
  end

  describe "casting from sub applicators" do
    defmodule Child do
      use JSV.Schema
      defschema %{type: :object, properties: %{foo: %{type: :string}}, required: [:foo]}
    end

    defmodule OtherChild do
      use JSV.Schema
      defschema %{type: :object, properties: %{baz: %{type: :string}}, required: [:baz]}
    end

    defcast topcast(value) do
      {:ok, {:top, value}}
    end

    # Tests made to fix a bug.
    #
    # When using oneOf with a desfchema module in the oneOf, the value is cast
    # before some keywords are executed, like required: ["foo"] that will not
    # work since the value has been casted to a struct with a :foo key.
    #
    # To solve oneOf we can just change priorities of vocabularies. But the core
    # has a low priority, but core handles $ref as well that can result in a
    # cast.
    #
    # Other cases may arise: different cast in properties/foo and
    # patternProperties/f.*o that will apply to the same data
    test "casting from oneOf will skip other properties" do
      # in this test, as there is no other cast, we will cast the value to
      # the subschema in oneOf and the `bar` property will be lost.
      schema = %{
        type: :object,
        properties: %{
          bar: %{type: :integer}
        },
        required: [:bar],
        oneOf: [Child]
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1}
      assert %Child{} = JSV.validate!(data, root)
    end

    test "casting from ref will skip other properties" do
      # Here to the "bar" property will be lost
      schema = %{
        type: :object,
        properties: %{
          bar: %{type: :integer}
        },
        required: [:bar],
        "$ref": Internal.module_to_uri(Child)
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1}
      assert %Child{} = JSV.validate!(data, root)
    end

    test "casting from oneOf/ref will skip other properties" do
      # Here to the "bar" property will be lost
      schema = %{
        type: :object,
        properties: %{
          bar: %{type: :integer}
        },
        required: [:bar],
        oneOf: [
          %{"$ref": Internal.module_to_uri(Child)}
        ]
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1}
      assert %Child{} = JSV.validate!(data, root)
    end

    test "cast from allOf will cast if there is a single module" do
      schema = %{
        type: :object,
        allOf: [
          %{properties: %{bar: %{type: :integer}}, required: [:bar]},
          Child
        ]
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1}
      assert %Child{} = JSV.validate!(data, root)
    end

    test "multiple cast from allOf use the first one" do
      schema = %{
        type: :object,
        allOf: [Child, OtherChild]
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1, "baz" => "goodbye"}
      assert %Child{} = JSV.validate!(data, root)
    end

    test "parent cast overrides the child" do
      schema = %{
        type: :object,
        "x-jsv-cast": [__MODULE__, "topcast"],
        allOf: [
          %{properties: %{bar: %{type: :integer}}, required: [:bar]},
          Child
        ]
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1}
      assert {:top, %{"bar" => 1, "foo" => "hello"}} = JSV.validate!(data, root)
    end

    test "with if/else" do
      # The "if" will take priority as defined in the cast_priority function of
      # the applicator vocabulary.
      schema = %{
        type: :object,
        if: %{required: [:bar]},
        then: Child,
        allOf: [OtherChild]
      }

      root = JSV.build!(schema)
      data = %{"foo" => "hello", "bar" => 1, "baz" => "goodbye"}
      assert %Child{} = JSV.validate!(data, root)
    end
  end
end
