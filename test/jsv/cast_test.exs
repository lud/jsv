# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.CastTest do
  alias JSV.Resolver.Internal
  use JSV.Schema
  use ExUnit.Case, async: true

  describe "legacy jsv-cast support" do
    test "cast is not called when data is invalid" do
      defmodule LegacyNotCalled do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :will_not_be_called, 1}
        end

        def will_not_be_called(_) do
          raise "called!"
        end
      end

      schema = %{
        type: :integer,
        "jsv-cast": [to_string(LegacyNotCalled), "some_tag"]
      }

      root = JSV.build!(schema)
      assert {:error, _validation_error} = JSV.validate("hello", root)
    end

    test "cast returns an ok tuple" do
      defmodule LegacyOk do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :do_cast, 1}
        end

        def do_cast("hello") do
          {:ok, :some_cast_value}
        end
      end

      schema = %{
        type: :string,
        "jsv-cast": [to_string(LegacyOk), "some_tag"]
      }

      root = JSV.build!(schema)
      assert {:ok, :some_cast_value} = JSV.validate("hello", root)
    end

    test "cast returns an error tuple" do
      defmodule LegacyError do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :returns_error, 1}
        end

        def returns_error("hello") do
          {:error, :bad_stuff}
        end

        def format_error(["some_tag"], :bad_stuff, "hello") do
          %{kind: :custom_kind, message: "legacy err"}
        end
      end

      schema = %{
        type: :string,
        "jsv-cast": [to_string(LegacyError), "some_tag"]
      }

      root = JSV.build!(schema)
      assert {:error, validation_error} = JSV.validate("hello", root)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "legacy err", kind: :custom_kind}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error, keys: :atoms)
    end

    test "cast raises an error" do
      defmodule LegacyRaises do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :boom, 1}
        end

        def boom(_data) do
          raise "boom from legacy cast"
        end
      end

      schema = %{
        type: :string,
        "jsv-cast": [to_string(LegacyRaises), "some_tag"]
      }

      root = JSV.build!(schema)

      assert_raise RuntimeError, ~r/boom from legacy cast/, fn ->
        JSV.validate("hello", root)
      end
    end
  end

  describe "using x-jsv-cast with a manual __jsv__ callback" do
    test "can cast raw data to arbitrary data" do
      defmodule ExpectsString do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :do_cast, 1}
        end

        def do_cast("hello") do
          {:ok, :some_cast_value}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [[to_string(ExpectsString), "some_tag"]]
      }

      root = JSV.build!(schema)
      assert {:ok, :some_cast_value} = JSV.validate("hello", root)
    end

    test "not called when data is invalid" do
      defmodule XExpectsInteger do
        def __jsv__({:cast, _args}) do
          {__MODULE__, :will_not_be_called, 1}
        end

        def will_not_be_called(_) do
          raise("will not be called")
        end
      end

      schema = %{
        type: :integer,
        "x-jsv-cast": [[to_string(XExpectsInteger), "some_tag"]]
      }

      root = JSV.build!(schema)
      assert {:error, _validation_error} = JSV.validate("hello", root)
    end

    test "can return an error" do
      defmodule XReturnsError do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :do_cast, 1}
        end

        def do_cast("hello") do
          {:error, {:expected, "goodbye", "hello", :in, self()}}
        end

        def format_error(["some_tag"], {:expected, "goodbye", "hello", :in, pid}, "hello")
            when pid == self() do
          %{kind: :custom_kind, message: "this is an err msg"}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [[to_string(XReturnsError), "some_tag"]]
      }

      root = JSV.build!(schema)

      assert {:error, validation_error} = JSV.validate("hello", root)

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

    test "does not crash when __jsv__ has no matching clause" do
      defmodule XDoesNotKnowTag do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :whatever, 1}
        end

        def whatever(_) do
          {:ok, :whatever}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [[to_string(XDoesNotKnowTag), "ANOTHER TAG"]]
      }

      assert {:error, _build_error} = JSV.build(schema)
    end

    test "does not crash when module has no __jsv__" do
      schema = %{
        type: :string,
        "x-jsv-cast": [["Elixir.System", "stop"]]
      }

      assert {:error, _build_error} = JSV.build(schema)
    end

    test "errors from nested calls within __jsv__ propagate at build time" do
      defmodule XNestedUnexportedFunction do
        def __jsv__({:cast, ["some_tag" | _]}) do
          UnknownModule.a_function()
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [[to_string(XNestedUnexportedFunction), "some_tag"]]
      }

      assert_raise UndefinedFunctionError, ~r/UnknownModule.a_function.*is undefined/, fn ->
        JSV.build!(schema)
      end
    end

    test "function clause errors within the caster propagate at validation time" do
      defmodule XNestedFunctionClauseError do
        def __jsv__({:cast, ["some_tag" | _]}) do
          {__MODULE__, :do_cast, 1}
        end

        def do_cast("hello") do
          local_fun(1234)
        end

        defp local_fun(:x) do
          {:ok, "hello"}
        end
      end

      schema = %{
        type: :string,
        "x-jsv-cast": [[to_string(XNestedFunctionClauseError), "some_tag"]]
      }

      root = JSV.build!(schema)

      assert_raise FunctionClauseError,
                   ~r/no function clause matching in.*XNestedFunctionClauseError.local_fun/,
                   fn ->
                     JSV.validate("hello", root)
                   end
    end
  end

  defmodule ArityDefcastMod do
    use JSV.Schema

    defcast append_suffix(data, args) do
      [suffix] = args
      {:ok, data <> suffix}
    end

    defcast append_suffix_vctx(data, args, _vctx) do
      [suffix] = args
      {:ok, data <> suffix}
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

    # Arity 1 - data only; helper /0
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

    # Arity 2 - data + args; helper /1 taking extras list
    defcast with_args(data, args) do
      _ = args
      to_upper_if_string(data)
    end

    # Arity 3 - data + args + vctx; helper /1 taking extras list
    defcast with_args_vctx(data, args, vctx) do
      _ = args
      _ = vctx
      to_upper_if_string(data)
    end

    # Arity 3 - extracts a suffix from args; helper /1
    defcast with_suffix(data, args, vctx) do
      _ = vctx
      [suffix] = args

      case to_upper_if_string(data) do
        {:ok, up} -> {:ok, up <> suffix}
        err -> err
      end
    end

    # Arity 3 - extracts prefix and suffix from args; helper /1
    defcast with_two_extras(data, args, vctx) do
      _ = vctx
      [prefix, suffix] = args

      case to_upper_if_string(data) do
        {:ok, up} -> {:ok, prefix <> up <> suffix}
        err -> err
      end
    end

    # Local function form - arity 1
    defcast :some_local_fun

    def some_local_fun(data) do
      to_upper_if_string(data)
    end

    # Manually defined /0 helper for the atom-form defcast above
    def some_local_fun do
      [to_string(__MODULE__), "some_local_fun"]
    end

    defcast "some local tag", :some_local_fun

    # Local function form - arity 2 (data + args)
    defcast :local_with_args

    def local_with_args(data, _args) do
      to_upper_if_string(data)
    end

    # Local function form - arity 3 (data + args + vctx)
    defcast :local_with_args_vctx

    def local_with_args_vctx(data, _args, _vctx) do
      to_upper_if_string(data)
    end

    # Local function form - arity 3, extracts suffix from args
    defcast :local_with_suffix

    def local_with_suffix(data, args, _vctx) do
      [suffix] = args

      case to_upper_if_string(data) do
        {:ok, up} -> {:ok, up <> suffix}
        err -> err
      end
    end

    # Local function form - arity 3, extracts prefix and suffix from args
    defcast :local_with_two_extras

    def local_with_two_extras(data, args, _vctx) do
      [prefix, suffix] = args

      case to_upper_if_string(data) do
        {:ok, up} -> {:ok, prefix <> up <> suffix}
        err -> err
      end
    end

    def format_error(args, {:expected_string, data}, data) do
      "expected a string but got: #{inspect(data)} in #{inspect(args)}"
    end

    def format_error(["with_rescue_block"], :unknown_existing_atom, string) do
      "not an existing atom representation: #{inspect(string)}"
    end
  end

  describe "macros used in CastExample module" do
    # Wrap a single caster sub-array in the top-level x-jsv-cast list.
    defp caster_list(sub) when is_list(sub) do
      [sub]
    end

    defp call_with(caster, data) when is_binary(caster) when is_integer(caster) do
      sub = [to_string(CastExample), caster]
      schema = %{"x-jsv-cast": caster_list(sub)}
      root = JSV.build!(schema)
      JSV.validate(data, root)
    end

    defp call_with_args(tag, extras, data) do
      sub = [to_string(CastExample), tag | extras]
      schema = %{"x-jsv-cast": caster_list(sub)}
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
                    formatter: JSV.Vocabulary.Cast
                  } = err
                ]
              } = e} = call_with(caster, data)

      assert err.args[:cast].module == JSV.CastTest.CastExample
      assert err.args[:reason] != nil

      assert %{} = JSV.normalize_error(e)
      err.args[:reason]
    end

    defp try_caster(fun, tag) do
      _ = :some_existing_atom
      valid_data = "some_existing_atom"
      valid_cast = "SOME_EXISTING_ATOM"
      invalid_data = 123_456

      if fun != nil do
        # The /0 helper returns the caster wire form
        assert [to_string(CastExample), tag] == apply(CastExample, fun, [])
        # The /1 handler is callable with just data
        assert {:ok, ^valid_cast} = apply(CastExample, fun, [valid_data])
      end

      assert ^valid_cast = cast_ok(tag, valid_data)
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

    test "defcast with data + args (arity 2)" do
      assert {:ok, "HELLO"} = call_with("with_args", "hello")
    end

    test "defcast with data + args + vctx (arity 3, no extras)" do
      assert {:ok, "HELLO"} = call_with("with_args_vctx", "hello")
    end

    test "defcast with data + args + vctx, one extra arg" do
      assert {:ok, "HELLO!"} = call_with_args("with_suffix", ["!"], "hello")
    end

    test "defcast with data + args + vctx, two extra args" do
      assert {:ok, ">>HELLO<<"} = call_with_args("with_two_extras", [">>", "<<"], "hello")
    end

    test "local fun with data + args (arity 2)" do
      assert {:ok, "HELLO"} = call_with("local_with_args", "hello")
    end

    test "local fun with data + args + vctx (arity 3, no extras)" do
      assert {:ok, "HELLO"} = call_with("local_with_args_vctx", "hello")
    end

    test "local fun with data + args + vctx, one extra arg" do
      assert {:ok, "HELLO?"} = call_with_args("local_with_suffix", ["?"], "hello")
    end

    test "local fun with data + args + vctx, two extra args" do
      assert {:ok, "[HELLO]"} = call_with_args("local_with_two_extras", ["[", "]"], "hello")
    end

    test "defcast helper arity" do
      mod_str = to_string(CastExample)

      # arity 1 handler -> helper /0, returns [mod_str, tag]
      assert [^mod_str, "with_do_block"] = CastExample.with_do_block()
      assert [^mod_str, "with_rescue_block"] = CastExample.with_rescue_block()

      # arity 2/3 handler -> helper /1 taking extras list, spliced into wire form
      assert [^mod_str, "with_args"] = CastExample.with_args([])
      assert [^mod_str, "with_args", "x"] = CastExample.with_args(["x"])
      assert [^mod_str, "with_args_vctx"] = CastExample.with_args_vctx([])
      assert [^mod_str, "with_suffix", "!"] = CastExample.with_suffix(["!"])
      assert [^mod_str, "with_two_extras", ">>", "<<"] = CastExample.with_two_extras([">>", "<<"])
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
        defmodule UsesTooManyArgs do
          use JSV.Schema

          defcast with_too_many(a, b, c, d) do
            {:ok, a}
          end
        end
      end

      assert_raise ArgumentError, ~r/invalid defcast/, fn ->
        defmodule UsesBadAtom do
          use JSV.Schema
          defcast :aaa, 1234
        end
      end

      assert_raise ArgumentError, ~r/invalid defcast/, fn ->
        defmodule UsesBadShape do
          use JSV.Schema

          defcast :tag, hello(data) do
            {:ok, data}
          end
        end
      end
    end
  end

  describe "cast handler arity dispatch" do
    test "legacy jsv-cast dispatches to arity 2 handler" do
      defmodule LegacyArity2Handler do
        def __jsv__({:cast, ["tag" | _]}) do
          {__MODULE__, :do_cast, 2}
        end

        def do_cast(data, ["tag"]) do
          {:ok, {data, :arity2}}
        end
      end

      schema = %{type: :string, "jsv-cast": [to_string(LegacyArity2Handler), "tag"]}
      root = JSV.build!(schema)
      assert {:ok, {"hello", :arity2}} = JSV.validate("hello", root)
    end

    test "legacy jsv-cast dispatches to arity 3 handler" do
      defmodule LegacyArity3Handler do
        def __jsv__({:cast, ["tag" | _]}) do
          {__MODULE__, :do_cast, 3}
        end

        def do_cast(data, ["tag"], _vctx) do
          {:ok, {data, :arity3}}
        end
      end

      schema = %{type: :string, "jsv-cast": [to_string(LegacyArity3Handler), "tag"]}
      root = JSV.build!(schema)
      assert {:ok, {"hello", :arity3}} = JSV.validate("hello", root)
    end

    test "x-jsv-cast defcast with arity 2 passes args correctly" do
      schema = %{"x-jsv-cast": [ArityDefcastMod.append_suffix(["!"])]}
      root = JSV.build!(schema)
      assert {:ok, "hello!"} = JSV.validate("hello", root)
    end

    test "x-jsv-cast defcast with arity 3 passes args and vctx correctly" do
      schema = %{"x-jsv-cast": [ArityDefcastMod.append_suffix_vctx(["?"])]}
      root = JSV.build!(schema)
      assert {:ok, "hello?"} = JSV.validate("hello", root)
    end
  end

  describe "build errors for invalid cast handlers" do
    test "returns build error when handler function does not exist at any arity" do
      defmodule NoSuchFunction do
        def __jsv__({:cast, _}) do
          {__MODULE__, :this_function_does_not_exist}
        end
      end

      schema = %{"x-jsv-cast": [[to_string(NoSuchFunction), "tag"]]}

      assert {:error,
              %JSV.BuildError{
                reason: {:invalid_cast, ["Elixir.JSV.CastTest.NoSuchFunction", "tag"], JSV.CastTest.NoSuchFunction}
              }} = JSV.build(schema)
    end

    test "returns build error when handler function only exists at arity 4" do
      defmodule OnlyArity4 do
        # __jsv__ returns a 2-tuple, triggering arity discovery
        def __jsv__({:cast, _}) do
          {__MODULE__, :do_cast}
        end

        # only exported at arity 4, which is outside the valid 1..3 range
        def do_cast(_a, _b, _c, _d) do
          {:ok, :four}
        end
      end

      schema = %{"x-jsv-cast": [[to_string(OnlyArity4), "tag"]]}

      assert {:error,
              %JSV.BuildError{
                reason: {:invalid_cast, ["Elixir.JSV.CastTest.OnlyArity4", "tag"], JSV.CastTest.OnlyArity4}
              }} = JSV.build(schema)
    end
  end

  describe "x-jsv-cast multicasting" do
    defmodule MultiCaster do
      def __jsv__({:cast, _args}) do
        {__MODULE__, :cast, 3}
      end

      def cast(data, ["upcase"], _vctx) when is_binary(data) do
        {:ok, String.upcase(data)}
      end

      def cast(data, ["append", suffix], _vctx) when is_binary(data) do
        {:ok, data <> suffix}
      end

      def cast(data, ["reverse"], _vctx) when is_binary(data) do
        {:ok, String.reverse(data)}
      end

      def cast(_data, ["fail"], _vctx) do
        {:error, :deliberate_failure}
      end

      def cast(data, [], _vctx) when is_binary(data) do
        {:ok, String.upcase(data)}
      end

      def format_error(["fail"], :deliberate_failure, _data) do
        %{kind: :multicast_fail, message: "deliberate failure"}
      end
    end

    defp multi(tag_and_args) when is_list(tag_and_args) do
      [to_string(MultiCaster) | tag_and_args]
    end

    test "two casts are called in order" do
      schema = %{
        type: :string,
        "x-jsv-cast": [
          multi(["upcase"]),
          multi(["append", "!"])
        ]
      }

      root = JSV.build!(schema)
      # First upcase "hello" -> "HELLO", then append "!" -> "HELLO!"
      assert {:ok, "HELLO!"} = JSV.validate("hello", root)
    end

    test "three casts are called in order" do
      schema = %{
        type: :string,
        "x-jsv-cast": [
          multi(["append", "-suffix"]),
          multi(["upcase"]),
          multi(["reverse"])
        ]
      }

      root = JSV.build!(schema)
      # "hello" -> "hello-suffix" -> "HELLO-SUFFIX" -> "XIFFUS-OLLEH"
      assert {:ok, "XIFFUS-OLLEH"} = JSV.validate("hello", root)
    end

    test "a failing cast stops the chain without calling subsequent casts" do
      schema = %{
        type: :string,
        "x-jsv-cast": [
          multi(["upcase"]),
          multi(["fail"]),
          multi(["append", "!"])
        ]
      }

      root = JSV.build!(schema)
      assert {:error, validation_error} = JSV.validate("hello", root)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "deliberate failure", kind: :multicast_fail}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error, keys: :atoms)
    end

    test "first cast failure prevents all subsequent casts" do
      schema = %{
        type: :string,
        "x-jsv-cast": [
          multi(["fail"]),
          multi(["upcase"]),
          multi(["append", "!"])
        ]
      }

      root = JSV.build!(schema)
      assert {:error, _validation_error} = JSV.validate("hello", root)
    end

    test "string shorthand in list is normalized and participates in multicast" do
      schema = %{
        type: :string,
        "x-jsv-cast": [
          to_string(MultiCaster),
          multi(["append", "?"])
        ]
      }

      root = JSV.build!(schema)
      # First upcase "hello" -> "HELLO" (empty args clause), then append "?" -> "HELLO?"
      assert {:ok, "HELLO?"} = JSV.validate("hello", root)
    end
  end

  describe "x-jsv-cast edge cases" do
    test "empty casts list is valid and leaves data unchanged" do
      schema = %{type: :string, "x-jsv-cast": []}
      root = JSV.build!(schema)
      assert {:ok, "hello"} = JSV.validate("hello", root)
    end

    test "cast returning a non-result value produces a bad cast return value error" do
      defmodule BadReturnCaster do
        def __jsv__({:cast, _}) do
          {__MODULE__, :do_cast, 1}
        end

        def do_cast(_data) do
          :not_a_tuple
        end
      end

      schema = %{"x-jsv-cast": [[to_string(BadReturnCaster), "tag"]]}
      root = JSV.build!(schema)
      assert {:error, validation_error} = JSV.validate("hello", root)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "bad cast return value", kind: :cast}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(validation_error, keys: :atoms)
    end

    test "[[]] is a build error - empty caster has no module" do
      schema = %{"x-jsv-cast": [[]]}
      assert_raise JSV.BuildError, ~r"malformed", fn -> JSV.build!(schema) end
    end
  end

  describe "jsv-cast and x-jsv-cast mutual exclusivity" do
    test "schema with both keywords is a build error" do
      defmodule BothKeywordsMod do
        def __jsv__({:cast, ["tag" | _]}) do
          {__MODULE__, :do_cast, 1}
        end

        def do_cast(data) do
          {:ok, data}
        end
      end

      schema = %{
        "jsv-cast": [to_string(BothKeywordsMod), "tag"],
        "x-jsv-cast": [[to_string(BothKeywordsMod), "tag"]]
      }

      e = catch_error(JSV.build!(schema))

      assert %JSV.BuildError{reason: :mixed_casts, action: :"x-jsv-cast", build_path: "#"} = e
      assert Exception.message(e) =~ "both jsv-cast and x-jsv-cast on the same schema"
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

    test "casting from oneOf will skip other properties" do
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
        "x-jsv-cast": [[to_string(__MODULE__), "topcast"]],
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
