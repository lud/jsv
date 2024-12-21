defmodule JSV.Vocabulary.V202012.Core do
  alias JSV.Builder
  alias JSV.Key
  alias JSV.Ref
  alias JSV.Resolver.Resolved
  alias JSV.Validator
  use JSV.Vocabulary, priority: 100

  def init_validators(_) do
    []
  end

  take_keyword :"$ref", raw_ref, acc, builder, _ do
    with {:ok, ref} <- Ref.parse(raw_ref, builder.ns),
         {:ok, ref, builder} <- maybe_swap_ref(ref, builder) do
      ok_put_ref(ref, :"$ref", acc, builder)
    end
  end

  take_keyword :"$defs", _defs, acc, builder, _ do
    {:ok, acc, builder}
  end

  take_keyword :"$anchor", _anchor, acc, builder, _ do
    {:ok, acc, builder}
  end

  take_keyword :"$dynamicRef", raw_ref, acc, builder, _ do
    # We need to ensure that the dynamic ref is in a schema where a
    # corresponding dynamic anchor is present. Otherwise we are just a normal
    # ref to an anchor (and we do not check its existence at this point.)

    with {:ok, %{dynamic?: true, kind: :anchor, arg: anchor} = ref} <- Ref.parse_dynamic(raw_ref, builder.ns),
         {:ok, builder} <- Builder.ensure_resolved(builder, ref),
         {:ok, %{raw: raw}} <- Builder.fetch_resolved(builder, ref.ns),
         :ok <- find_local_dynamic_anchor(raw, anchor) do
      # The "dynamic" information is carried in the ref from Ref.parse_dynamic,
      # so we just return a :ref tuple. This allows to treat dynamic refs
      # without corresponding dynamic anchors as regular refs.
      ok_put_ref(ref, :"$dynamicRef", acc, builder)
    else
      {:error, {:no_such_dynamic_anchor, _}} -> ok_put_ref(raw_ref, :"$dynamicRef", acc, builder)
      {:ok, %{dynamic?: false} = ref} -> ok_put_ref(ref, :"$dynamicRef", acc, builder)
      {:error, _} = err -> err
    end
  end

  take_keyword :"$dynamicAnchor", _anchor, acc, builder, _ do
    {:ok, acc, builder}
  end

  consume_keyword :"$comment"
  consume_keyword :"$id"
  consume_keyword :"$schema"
  consume_keyword :"$vocabulary"
  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    list
  end

  def ok_put_ref(%Ref{} = ref, eval_path, acc, builder) do
    builder = Builder.stage_build(builder, ref)
    {:ok, [{:ref, eval_path, Key.of(ref)} | acc], builder}
  end

  def ok_put_ref(raw_ref, eval_path, acc, builder) when is_binary(raw_ref) do
    with {:ok, ref} <- Ref.parse(raw_ref, builder.ns) do
      ok_put_ref(ref, eval_path, acc, builder)
    end
  end

  # If the ref is a pointer but points to a schema with an $id we will swap the
  # ref to target that ID instead, so we can support skipping over boundaries
  # when resolving dynamic refs by not adding intermediary scopes.
  def maybe_swap_ref(%{kind: :pointer} = ref, builder) do
    with {:ok, builder} <- Builder.ensure_resolved(builder, ref),
         {:ok, resolved} <- Builder.fetch_resolved(builder, Key.of(ref)) do
      case resolved do
        %Resolved{raw: %{"$id" => _}, ns: ns} ->
          {:ok, new_ref} = Ref.parse(ns, :root)
          {:ok, new_ref, builder}

        _ ->
          {:ok, ref, builder}
      end
    end
  end

  def maybe_swap_ref(ref, builder) do
    {:ok, ref, builder}
  end

  # Look for a dynamic anchor in this schema without looking down in subschemas
  # that define an $id.
  defp find_local_dynamic_anchor(%{"$id" => _} = raw_schema, anchor) when is_map(raw_schema) do
    with :error <- do_find_local_dynamic_anchor(Map.delete(raw_schema, "$id"), anchor) do
      {:error, {:no_such_dynamic_anchor, anchor}}
    end
  end

  defp do_find_local_dynamic_anchor(%{"$id" => _}, _anchor) do
    :error
  end

  defp do_find_local_dynamic_anchor(%{} = raw_schema, anchor) do
    case raw_schema do
      %{"$dynamicAnchor" => ^anchor} ->
        :ok

      %{} ->
        raw_schema
        |> Map.drop(["properties"])
        |> Map.values()
        |> do_find_local_dynamic_anchor(anchor)
    end
  end

  defp do_find_local_dynamic_anchor([h | t], anchor) do
    case do_find_local_dynamic_anchor(h, anchor) do
      :ok -> :ok
      :error -> do_find_local_dynamic_anchor(t, anchor)
    end
  end

  defp do_find_local_dynamic_anchor(other, _anchor)
       when other == []
       when is_binary(other)
       when is_atom(other)
       when is_number(other) do
    :error
  end

  # ---------------------------------------------------------------------------

  def validate(data, vds, vctx) do
    Validator.iterate(vds, data, vctx, &validate_keyword/3)
  end

  def validate_keyword({:ref, eval_path, ref}, data, vctx) do
    Validator.validate_ref(data, ref, eval_path, vctx)
  end

  # ---------------------------------------------------------------------------
end
