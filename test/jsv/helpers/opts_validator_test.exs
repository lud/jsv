defmodule JSV.Helpers.OptsValidatorTest do
  use ExUnit.Case, async: true

  alias JSV.Helpers.OptsValidator

  doctest JSV.Helpers.OptsValidator

  defp accept_all(_key, value) do
    value
  end

  describe "validate/3" do
    test "returns the defaults unchanged for empty opts" do
      defaults = %{cast: true, cast_formats: false}
      assert OptsValidator.validate([], defaults, &accept_all/2) == defaults
    end

    test "does not call the validator for empty opts" do
      boom = fn _key, _value -> raise "should not be called" end
      assert OptsValidator.validate([], %{cast: true}, boom) == %{cast: true}
    end

    test "accumulates valid options into the defaults map" do
      assert OptsValidator.validate([a: 1, b: 2], %{}, &accept_all/2) == %{a: 1, b: 2}
    end

    test "provided options override defaults" do
      defaults = %{cast: true, cast_formats: false}

      assert OptsValidator.validate([cast: false], defaults, &accept_all/2) ==
               %{cast: false, cast_formats: false}
    end

    test "keeps defaults that are not overridden" do
      defaults = %{cast: true, cast_formats: false}

      assert OptsValidator.validate([key: :foo], defaults, &accept_all/2) ==
               %{cast: true, cast_formats: false, key: :foo}
    end

    test "the validator may transform the stored value" do
      assert OptsValidator.validate([n: 1], %{}, fn :n, v -> v * 2 end) == %{n: 2}
    end

    test "passes both the key and value to the validator" do
      parent = self()

      fun = fn key, value ->
        send(parent, {:seen, key, value})
        value
      end

      assert OptsValidator.validate([a: 1, b: 2], %{}, fun) == %{a: 1, b: 2}
      assert_received {:seen, :a, 1}
      assert_received {:seen, :b, 2}
    end

    test "the last value wins for duplicate keys" do
      assert OptsValidator.validate([a: 1, a: 2], %{}, &accept_all/2) == %{a: 2}
    end

    test "lets the validator's exception propagate" do
      fun = fn _key, _value -> OptsValidator.invalid_option!(:a, 1, "anything") end

      assert_raise ArgumentError, fn -> OptsValidator.validate([a: 1], %{}, fun) end
    end

    test "stops on the first raising option and does not evaluate later options" do
      fun = fn
        :b, _value -> raise "bad b"
        :c, _value -> raise "should not be reached"
        _key, value -> value
      end

      assert_raise RuntimeError, "bad b", fn ->
        OptsValidator.validate([a: 1, b: 2, c: 3], %{}, fun)
      end
    end

    test "raises on a non-tuple entry" do
      assert_raise ArgumentError, ~r/expected a \{key, value\} option tuple/, fn ->
        OptsValidator.validate([:nope], %{}, &accept_all/2)
      end
    end

    test "raises on a tuple with a non-atom key" do
      assert_raise ArgumentError, fn -> OptsValidator.validate([{"a", 1}], %{}, &accept_all/2) end
    end
  end

  describe "invalid_option!/3" do
    test "raises a descriptive ArgumentError" do
      assert_raise ArgumentError, ~s(invalid value for option :cast, expected a boolean, got: "yes"), fn ->
        OptsValidator.invalid_option!(:cast, "yes", "a boolean")
      end
    end
  end

  describe "unknown_option!/1" do
    test "raises with the offending key" do
      assert_raise ArgumentError, "unknown option :bogus", fn ->
        OptsValidator.unknown_option!(:bogus)
      end
    end
  end

  describe "validate/3 with a realistic JSV-style validator" do
    setup do
      defaults = %{cast: true, cast_formats: false}

      validator = fn
        :cast, value when is_boolean(value) -> value
        :cast_formats, value when is_boolean(value) -> value
        :key, value -> value
        key, value when key in [:cast, :cast_formats] -> OptsValidator.invalid_option!(key, value, "a boolean")
        key, _value -> OptsValidator.unknown_option!(key)
      end

      %{defaults: defaults, validator: validator}
    end

    test "applies defaults for empty opts", ctx do
      assert OptsValidator.validate([], ctx.defaults, ctx.validator) == ctx.defaults
    end

    test "merges provided opts over defaults", ctx do
      assert OptsValidator.validate([cast: false], ctx.defaults, ctx.validator) ==
               %{cast: false, cast_formats: false}
    end

    test "raises on an unknown option", ctx do
      assert_raise ArgumentError, "unknown option :bogus", fn ->
        OptsValidator.validate([bogus: 1], ctx.defaults, ctx.validator)
      end
    end

    test "raises on an invalid value", ctx do
      assert_raise ArgumentError, ~r/invalid value for option :cast/, fn ->
        OptsValidator.validate([cast: "yes"], ctx.defaults, ctx.validator)
      end
    end
  end
end
