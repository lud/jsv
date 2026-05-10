defmodule JSV.Cast do
  import JSV, only: [defcast: 2, defcast_module: 1]

  @moduledoc false

  defcast_module(:skip)

  defcast string_to_integer(data) do
    with true <- is_binary(data),
         {int, ""} <- Integer.parse(data) do
      {:ok, int}
    else
      _ -> {:error, "invalid integer representation"}
    end
  end

  defcast string_to_float(data) do
    with true <- is_binary(data),
         {float, ""} <- Float.parse(data) do
      {:ok, float}
    else
      _ -> {:error, "invalid floating point number representation"}
    end
  end

  defcast string_to_number(data) do
    with true <- is_binary(data),
         {:ok, number} <- parse_number(data) do
      {:ok, number}
    else
      _ -> {:error, "invalid number representation"}
    end
  end

  defp parse_number(data) do
    case Float.parse(data) do
      {float, ""} ->
        {:ok, float}

      _ ->
        case Integer.parse(data) do
          {int, ""} -> {:ok, int}
          _ -> :error
        end
    end
  end

  defcast string_to_boolean(data) do
    case data do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> {:error, "invalid boolean representation"}
    end
  end

  defcast string_to_existing_atom(data) do
    {:ok, String.to_existing_atom(data)}
  rescue
    ArgumentError -> {:error, "not an existing atom representation"}
  end

  defcast string_to_atom(data) do
    if is_binary(data) do
      {:ok, String.to_atom(data)}
    else
      {:error, "not an atom representation"}
    end
  end

  defcast string_to_atom_or_nil(data) do
    case data do
      b when is_binary(b) -> {:ok, String.to_atom(data)}
      nil -> {:ok, nil}
      _ -> {:error, "not an atom representation or nil"}
    end
  end

  # Custom declaration and implementation because the helper takes no argument
  # but the handler takes the mapping argument. This is not supported by defcast
  # yet.
  @jsv_casts {:keep, "aprops"}
  @spec atom_property_keys :: binary
  def atom_property_keys do
    "aprops"
  end

  @spec atom_property_keys(map, [{binary, %{binary => atom}}]) :: {:ok, map}
  def atom_property_keys(data, [{keys, mapping} | _]) when is_map(data) do
    {map_raw, map_keep} = Map.split(data, keys)
    map_atoms = Map.new(map_raw, fn {k, v} -> {Map.fetch!(mapping, k), v} end)
    {:ok, Map.merge(map_keep, map_atoms)}
  end

  @doc false
  @spec format_error(term, term, term) :: binary
  def format_error(_, message, _) do
    message
  end

  defoverridable __jsv__: 2

  @spec __jsv__(tuple, JSV.Builder.t()) :: {tuple, JSV.Builder.t()}
  @doc false
  def __jsv__({:cast, ["string_to_atom" | _], _raw_schema}, builder) do
    case check_atoms_opt(builder) do
      {true, builder} -> {{__MODULE__, :string_to_atom, 1}, builder}
      {false, builder} -> {:nocast, builder}
    end
  end

  def __jsv__({:cast, ["string_to_atom_or_nil" | _], _raw_schema}, builder) do
    case check_atoms_opt(builder) do
      {true, builder} -> {{__MODULE__, :string_to_atom_or_nil, 1}, builder}
      {false, builder} -> {:nocast, builder}
    end
  end

  def __jsv__({:cast, ["aprops" | _], raw_schema}, builder) do
    case check_atoms_opt(builder) do
      {false, builder} ->
        {:nocast, builder}

      {true, builder} ->
        mapping =
          case raw_schema do
            %{properties: properties} when is_map(properties) -> atom_mapping(properties)
            %{"properties" => properties} when is_map(properties) -> atom_mapping(properties)
            _ -> nil
          end

        case mapping do
          nil -> {:nocast, builder}
          _ -> {{__MODULE__, :atom_property_keys, 2, [mapping]}, builder}
        end
    end
  end

  def __jsv__({:cast, _, _} = cast, builder) do
    super(cast, builder)
  end

  defp atom_mapping(properties) do
    Enum.map_reduce(properties, %{}, fn
      {k, _}, acc when is_binary(k) -> {k, Map.put(acc, k, String.to_atom(k))}
    end)
  end

  @unsafe_atoms_warning "The :atoms option was not defined on JSV schema build options. " <>
                          "This option defaults to `true` for backwards compatibility reasons, " <>
                          "but it is now required to pass it explicitly: " <>
                          "`JSV.build(schema, atoms: true)`\n\n" <>
                          "This option is safe to use for schemas that are trusted " <>
                          "(files from the codebase, first party remote sources, etc.). " <>
                          "Prefer setting `false` for schemas built dynamically at runtime."

  # TODO(v2): Default building atoms to false
  @default_atoms_build true

  defp check_atoms_opt(builder) do
    case builder.opts[:atoms] do
      nil -> {@default_atoms_build, JSV.Builder.warn(builder, :unsafe_atoms, @unsafe_atoms_warning)}
      bool -> {bool, builder}
    end
  end
end
