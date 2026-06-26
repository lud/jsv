defmodule JSV.Helpers.OptsValidator do
  @moduledoc """
  Validation helper for JSV public API options.
  """

  @type key :: atom
  @type validator :: (key, term -> term)

  @doc """
  Validates `opts` against `fun`, accumulating values into the `defaults` map and
  returning the merged map.

  The validator is called as `fun.(key, value)` and must return the value to
  store. Invalid options should raise (see `invalid_option!/3` and
  `unknown_option!/1`).

      iex> JSV.Helpers.OptsValidator.validate([a: 1, b: 2], %{}, fn _key, value -> value*2 end)
      %{a: 2, b: 4}

      iex> JSV.Helpers.OptsValidator.validate([cast: false], %{cast: true}, fn _key, value -> value end)
      %{cast: false}

      iex> JSV.Helpers.OptsValidator.validate([{:cast, :hello}], %{}, fn key, value ->
      ...>   JSV.Helpers.OptsValidator.invalid_option!(key, value, "a boolean")
      ...> end)
      ** (ArgumentError) invalid value for option :cast, expected a boolean, got: :hello

      iex> JSV.Helpers.OptsValidator.validate([:foo], %{cast: true}, fn _key, value -> value end)
      ** (ArgumentError) expected a {key, value} option tuple, got: :foo
  """
  @spec validate(keyword, map, validator) :: map
  def validate(opts, defaults, fun)
      when is_list(opts) and is_map(defaults) and is_function(fun, 2) do
    reduce(opts, defaults, fun)
  end

  defp reduce([], acc, _fun) do
    acc
  end

  defp reduce([{key, value} | rest], acc, fun) when is_atom(key) do
    reduce(rest, Map.put(acc, key, fun.(key, value)), fun)
  end

  defp reduce([invalid | _rest], _acc, _fun) do
    raise ArgumentError, "expected a {key, value} option tuple, got: #{inspect(invalid)}"
  end

  @doc """
  Raises an `ArgumentError` describing an option whose value did not pass
  validation. `expected` is a human description such as `"a boolean"`.

      iex> JSV.Helpers.OptsValidator.invalid_option!(:cast, "yes", "a boolean")
      ** (ArgumentError) invalid value for option :cast, expected a boolean, got: "yes"
  """
  @spec invalid_option!(key, term, String.t()) :: no_return()
  def invalid_option!(key, value, expected) when is_binary(expected) do
    raise ArgumentError, "invalid value for option #{inspect(key)}, expected #{expected}, got: #{inspect(value)}"
  end

  @doc """
  Raises an `ArgumentError` describing an unknown option key.

      iex> JSV.Helpers.OptsValidator.unknown_option!(:bogus)
      ** (ArgumentError) unknown option :bogus
  """
  @spec unknown_option!(key) :: no_return()
  def unknown_option!(key) do
    raise ArgumentError, "unknown option #{inspect(key)}"
  end

  @doc false
  @spec validate_boolean(atom, term) :: boolean
  def validate_boolean(key, value) do
    case value do
      true -> true
      false -> false
      other -> invalid_option!(key, other, "a boolean")
    end
  end
end
