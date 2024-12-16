defmodule JSV.JsonTools do
  @moduledoc """
  Collection of helpers to work with json.
  """

  def encode_ordered(data) do
    encode_ordered(data, default_ordering_mapper(), [])
  end

  def encode_ordered(data, jason_opts) when is_list(jason_opts) do
    encode_ordered(data, default_ordering_mapper(), jason_opts)
  end

  def encode_ordered(data, mapper) when is_function(mapper, 1) do
    encode_ordered(data, mapper, [])
  end

  def encode_ordered!(data) do
    encode_ordered!(data, default_ordering_mapper(), [])
  end

  def encode_ordered!(data, jason_opts) when is_list(jason_opts) do
    encode_ordered!(data, default_ordering_mapper(), jason_opts)
  end

  def encode_ordered!(data, mapper) when is_function(mapper, 1) do
    encode_ordered!(data, mapper, [])
  end

  @doc """
  Uses `Jason.encode/2` with the given `data` and `jason_opts` but ensures that
  the JSON objects have their properties written according to the `mapper`.

  The `mapper` argument is a function that receives a tuple of `{key, value}`
  for every pair of every map of the data, and must return a term whom the
  ordering is based on.
  """
  @spec encode_ordered(term, ({term, term} -> term), [Jason.encode_opt()]) ::
          {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()}
  def encode_ordered(data, mapper, jason_opts) do
    Jason.encode(fmap_ordered_keys(data, mapper), jason_opts)
  end

  @doc """
  Same as `encode_ordered/3` but using `Jason.encode!/2`.
  """
  @spec encode_ordered!(term, ({term, term} -> term), [Jason.encode_opt()]) :: String.t() | no_return()
  def encode_ordered!(data, mapper, jason_opts) do
    Jason.encode!(fmap_ordered_keys(data, mapper), jason_opts)
  end

  def default_ordering_mapper do
    fn {k, _} -> to_string(k) end
  end

  defp fmap_ordered_keys(map, mapper) when is_map(map) do
    map
    |> Map.delete(:__struct__)
    |> Enum.sort_by(mapper)
    |> Enum.map(fn {k, v} -> {k, fmap_ordered_keys(v, mapper)} end)
    |> Jason.OrderedObject.new()
  end

  defp fmap_ordered_keys(list, mapper) when is_list(list) do
    Enum.map(list, &fmap_ordered_keys(&1, mapper))
  end

  defp fmap_ordered_keys(other, _) do
    other
  end
end
