defmodule JSV.Vocabulary.Cast do
  alias JSV.Helpers.StringExt
  alias JSV.Validator
  use JSV.Vocabulary, priority: 900

  @moduledoc false

  @impl true
  def init_validators([]) do
    %{}
  end

  take_keyword :"jsv-cast", [module_str, arg], vds, builder, _ do
    case StringExt.safe_string_to_existing_module(module_str) do
      {:ok, module} -> {:ok, Map.put(vds, :"jsv-cast", {module, arg}), builder}
      {:error, _} = err -> err
    end
  end

  ignore_any_keyword()

  @impl true
  def finalize_validators(map) do
    case map_size(map) do
      0 -> :ignore
      _ -> map
    end
  end

  @impl true

  def validate(data, %{"jsv-cast": {module, arg}}, vctx) do
    cond do
      Validator.error?(vctx) ->
        {:ok, data, vctx}

      vctx.opts[:cast] ->
        case module.__jsv__(arg, data) do
          {:ok, new_data} ->
            {:ok, new_data, vctx}

          {:error, reason} ->
            raise "Cast error"
        end

      :other ->
        {:ok, data, vctx}
    end
  end
end

IO.warn("todo handle cast error")
