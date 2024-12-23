defmodule JSV.AtomTools do
  @moduledoc false
  alias JSV.Schema

  # # Tries Map.fetch/2 with both atom and binary key.  The first attempt is made
  # # with the binary key because we expect to work more often with raw schemas.
  # #
  # # Schemas defined with atom, as structs, are expected to be used and
  # # transformed to validators at compile-time, where a loss of performance is
  # # acceptable.
  # defmacro map_fetch_prop(map, atom_form) when is_atom(atom_form) do
  #   str_form = Atom.to_string(atom_form)

  #   quote bind_quoted: binding() do
  #     case map do
  #       %{^str_form => value} -> {:ok, value}
  #       %{^atom_form => value} -> {:ok, value}
  #       %{} -> :error
  #       other -> :erlang.error({:badmap, other}, [map, atom_form])
  #     end
  #   end
  # end

  # defmacro map_fetch_prop!(map, atom_form) when is_atom(atom_form) do
  #   str_form = Atom.to_string(atom_form)

  #   quote bind_quoted: binding() do
  #     case map do
  #       %{^str_form => value} -> value
  #       %{^atom_form => value} -> value
  #       %{} -> raise KeyError, key: atom_form, term: map
  #       other -> :erlang.error({:badmap, other}, [map, atom_form])
  #     end
  #   end
  # end

  # defmacro map_get_prop(map, atom_form, default) when is_atom(atom_form) do
  #   str_form = Atom.to_string(atom_form)

  #   quote bind_quoted: binding() do
  #     case map do
  #       %{^str_form => value} -> value
  #       %{^atom_form => value} -> value
  #       %{} -> default
  #       other -> :erlang.error({:badmap, other}, [map, atom_form, default])
  #     end
  #   end
  # end

  # # This is the only place in this library where the string $id is defined. So
  # # we are sure to always use the atom/binary compatible functions.
  # defmacro id_bin do
  #   "$id"
  # end

  def fmap_atom_to_binary(term) do
    # Checking before is faster (benchmark in ./tools)
    if atom_props?(term) do
      deatom(term)
    else
      term
    end
  end

  @doc false
  def deatom(term)

  def deatom(term) when term == nil when term == true when term == false do
    term
  end

  def deatom(term) when is_atom(term) do
    Atom.to_string(term)
  end

  def deatom(term) when is_binary(term) when is_number(term) do
    term
  end

  def deatom(%Schema{} = term) do
    deatom_schema_struct(term)
  end

  def deatom(term) when is_struct(term) do
    deatom(Map.from_struct(term))
  end

  def deatom(term) when is_map(term) do
    Map.new(term, fn {k, v} -> {deatom_key(k), deatom(v)} end)
  end

  def deatom([h | t]) do
    [deatom(h) | deatom(t)]
  end

  def deatom([]) do
    []
  end

  defp deatom_key(term) when term == nil when term == true when term == false do
    Atom.to_string(term)
  end

  defp deatom_key(term) do
    deatom(term)
  end

  def deatom_schema_struct(schema) do
    schema
    |> Map.from_struct()
    |> Enum.flat_map(fn
      {_, nil} -> []
      {:__struct__, _} -> []
      {k, v} -> [{deatom_key(k), deatom(v)}]
    end)
    |> Map.new()
  end

  @doc """
  Returns true if the given value (and sub values) contains atoms. Does not
  return true for `true`, `false` and `nil` except if keys in a map.
  """
  def atom_props?(term)

  def atom_props?(term) when is_map(term) do
    atom_props_iter?(:maps.iterator(term))
  end

  def atom_props?(term) when is_number(term) when is_binary(term) do
    false
  end

  # Special atoms as values does not count as an atom prop
  def atom_props?(term) when term == true when term == false when term == nil do
    false
  end

  def atom_props?(term) when is_atom(term) do
    true
  end

  def atom_props?([h | t]) do
    atom_props?(h) || atom_props?(t)
  end

  def atom_props?([]) do
    false
  end

  defp atom_props_iter?(iter) do
    case :maps.next(iter) do
      {k, v, iter} -> is_atom(k) || atom_props?(v) || atom_props_iter?(iter)
      :none -> false
    end
  end
end
