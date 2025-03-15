defmodule JSV.Vocabulary.Internal do
  alias JSV.Helpers.StringExt
  alias JSV.Validator
  use JSV.Vocabulary, priority: 900

  @moduledoc false

  @impl true
  def init_validators([]) do
    %{}
  end

  take_keyword :"jsv-struct", module_str, vds, builder, _ do
    case find_struct_module(module_str) do
      {:ok, module} -> {:ok, Map.put(vds, :"jsv-struct", module), builder}
    end
  end

  take_keyword :"jsv-schema", module_str, vds, builder, _ do
    case find_schema_module(module_str) do
      {:ok, module} -> {:ok, Map.put(vds, :"jsv-schema", module), builder}
    end
  end

  ignore_any_keyword()

  defp find_struct_module(module_str) do
    case StringExt.safe_string_to_existing_module(module_str) do
      {:ok, module} -> check_is_struct(module)
      {:error, _} = err -> err
    end
  end

  defp check_is_struct(module) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :__struct__, 0) do
      {:ok, module}
    else
      _ -> {:error, {:unknown_struct, module}}
    end
  end

  defp find_schema_module(module_str) do
    case StringExt.safe_string_to_existing_module(module_str) do
      {:ok, module} -> check_exports_schema(module)
      {:error, _} = err -> err
    end
  end

  defp check_exports_schema(module) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :schema, 0) do
      {:ok, module}
    else
      _ -> {:error, {:invalid_schema_module, module}}
    end
  end

  @impl true
  def finalize_validators(map) do
    case map_size(map) do
      0 -> :ignore
      _ -> map
    end
  end

  @impl true

  def validate(data, %{"jsv-struct": struct_module, "jsv-schema": schema_module}, vctx) do
    cond do
      Validator.error?(vctx) ->
        {:ok, data, vctx}

      vctx.opts[:cast_structs] ->
        keycast = schema_module.__jsv__(:keycast)
        # With defschema/1 the schema module is the same as the schema module,
        # so the defaults_overrides are an empty map because it is handled at
        # the struct level.

        props =
          data
          |> take_struct_keys(keycast)
          |> with_defaults_from(schema_module)

        {:ok, struct!(struct_module, props), vctx}

      :other ->
        {:ok, data, vctx}
    end
  end

  # When there is no other schema, the module that is the target struct also
  # defines the schema. This is the most common case and is the result of
  # defschema/1.
  def validate(data, %{"jsv-struct": struct_module}, vctx) do
    validate(data, %{"jsv-struct": struct_module, "jsv-schema": struct_module}, vctx)
  end

  defp take_struct_keys(data, keycast) do
    Enum.reduce(keycast, [], fn {str_key, atom_key}, acc ->
      case data do
        %{^str_key => v} -> [{atom_key, v} | acc]
        _ -> acc
      end
    end)
  end

  defp with_defaults_from(pairs, module) do
    Keyword.merge(module.__jsv__(:defaults_override), pairs)
  end
end
