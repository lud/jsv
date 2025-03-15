defmodule JSV.StructSupport do
  alias JSV.Schema

  @moduledoc """
  Utilities to work with structs defined by schemas.
  """

  @doc """
  Validates the given raw schema can be used to define a module struct or raises
  an exception.

  It will check the following:

  * Schema defines a type `object`.
  * Schema has `properties`.
  * `properties` is a map with atom keys.
  * `required`, if present, contains only atoms
  """
  @spec validate!(JSV.raw_schema()) :: :ok
  def validate!(schema) do
    validate_object_type!(schema)
    validate_properties_presence!(schema)
    validate_properties_keys!(schema)
    required = validate_required_type!(schema)
    validate_required_keys!(required)
    :ok
  end

  defp validate_object_type!(schema) do
    t =
      case schema do
        %{"type" => t} -> t
        %Schema{type: nil} -> raise ArgumentError, errmsg("must define the :object type")
        %{type: t} -> t
        _ -> raise ArgumentError, errmsg("must define the :object type")
      end

    case t do
      :object -> :ok
      "object" -> :ok
      other -> raise ArgumentError, errmsg("must define the :object type, got: #{inspect(other)}")
    end
  end

  defp validate_properties_presence!(schema) do
    case schema do
      %{"properties" => properties} when is_map(properties) -> :ok
      %{properties: properties} when is_map(properties) -> :ok
      _ -> raise ArgumentError, errmsg("properties must be a map")
    end
  end

  defp validate_properties_keys!(schema) do
    properties =
      case schema do
        %{"properties" => properties} -> properties
        %{properties: properties} -> properties
      end

    all_atom_keys? = Enum.all?(properties, fn {k, _} -> is_atom(k) end)

    if all_atom_keys? do
      :ok
    else
      raise ArgumentError, errmsg("properties must be defined with atom keys")
    end
  end

  defp validate_required_type!(schema) do
    required =
      case schema do
        %Schema{required: nil} -> []
        %{required: required} -> required
        %{"required" => required} -> required
        _ -> []
      end

    if not is_list(required) do
      raise ArgumentError, errmsg("required must be a list")
    end

    required
  end

  defp validate_required_keys!(list) do
    all_atoms? = Enum.all?(list, &is_atom/1)

    if all_atoms? do
      :ok
    else
      raise ArgumentError, errmsg("required must contain atom keys")
    end
  end

  @doc """
  Returns a list of `{binary_key, atom_key}` tuples for the given schema. The
  list is sorted by keys.

  The schema must be valid against `validate!1/`.

  This function accepts a second argument, which must be a module that
  implements a struct (with `defstruct/1`). When given, the function will
  validate that all schema keys exist in the given struct.
  """
  @spec keycast_pairs(JSV.raw_schema(), target :: nil | module) :: [{binary, atom}]

  def keycast_pairs(schema, target \\ nil)

  def keycast_pairs(schema, nil) do
    schema
    |> props!()
    |> Enum.map(fn {k, _} when is_atom(k) -> {Atom.to_string(k), k} end)
    |> Enum.sort()
  end

  def keycast_pairs(schema, target) do
    pairs = keycast_pairs(schema, nil)

    struct_keys = struct_keys(target)

    extra_keys =
      Enum.flat_map(pairs, fn {_, k} ->
        case k in struct_keys do
          true -> []
          false -> [k]
        end
      end)

    case extra_keys do
      [] ->
        pairs

      _ ->
        raise ArgumentError,
              "struct #{inspect(target)} does not define keys given in defschema_for/1 properties: #{inspect(extra_keys)}"
    end
  end

  defp struct_keys(module) do
    fields =
      try do
        module.__info__(:struct)
      rescue
        _ -> reraise ArgumentError, "module #{inspect(module)} does not define a struct", __STACKTRACE__
      end

    Enum.map(fields, & &1.field)
  end

  @doc """
  Returns a tuple where the first element is a list of schema `:properties` keys
  that do not have a `:default` value, and the second element is a list of
  `{key, default_value}` tuples. sorted by keys.

  Both lists are sorted by key.

  The schema must be valid against `validate!1/`.
  """
  @spec data_pairs_partition(JSV.raw_schema()) :: {[atom], keyword()}
  def data_pairs_partition(schema) do
    {no_defaults, with_defaults} =
      schema
      |> props!()
      |> Enum.reduce({[], []}, fn {k, subschema}, {no_defaults, with_defaults} when is_atom(k) ->
        case fetch_default(subschema) do
          {:ok, default} -> {no_defaults, [{k, default} | with_defaults]}
          :error -> {[k | no_defaults], with_defaults}
        end
      end)

    {Enum.sort(no_defaults), Enum.sort(with_defaults)}
  end

  @doc """
  Returns the `required` property of the schema or an empty list.

  The schema must be valid against `validate!1/`.
  """
  @spec list_required(JSV.raw_schema()) :: [atom()]
  def list_required(schema) do
    list =
      case schema do
        %{"required" => list} -> list
        %Schema{required: nil} -> []
        %{required: list} -> list
        _ -> []
      end

    true = is_list(list)
    list
  end

  defp props!(schema) do
    case schema do
      %{properties: properties} -> properties
      %{"properties" => properties} -> properties
    end
  end

  defp fetch_default(schema) do
    case schema do
      %{default: default} -> {:ok, default}
      %{"default" => default} -> {:ok, default}
      _ -> :error
    end
  end

  defp errmsg(msg) do
    "schema given to defschema/1 or defschema_for/2 " <> msg
  end
end
