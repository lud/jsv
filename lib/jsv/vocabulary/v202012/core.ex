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

  def take_keyword({"$ref", raw_ref}, acc, bld, _) do
    with {:ok, ref} <- Ref.parse(raw_ref, bld.ns),
         {:ok, ref, bld} <- maybe_swap_ref(ref, bld) do
      ok_put_ref(ref, acc, bld)
    end
  end

  def take_keyword({"$defs", _defs}, acc, bld, _) do
    {:ok, acc, bld}
  end

  def take_keyword({"$anchor", _anchor}, acc, bld, _) do
    {:ok, acc, bld}
  end

  def take_keyword({"$dynamicRef", raw_ref}, acc, bld, _) do
    # We need to ensure that the dynamic ref is in a schema where a
    # corresponding dynamic anchor is present. Otherwise we are just a normal
    # ref to an anchor (and we do not check its existence at this point.)

    with {:ok, %{dynamic?: true, kind: :anchor, arg: anchor} = ref} <- Ref.parse_dynamic(raw_ref, bld.ns),
         {:ok, bld} <- Builder.ensure_resolved(bld, ref),
         {:ok, %{raw: raw}} <- Builder.fetch_resolved(bld, ref.ns),
         :ok <- find_local_dynamic_anchor(raw, anchor) do
      # The "dynamic" information is carried in the ref from Ref.parse_dynamic,
      # so we just return a :ref tuple. This allows to treat dynamic refs
      # without corresponding dynamic anchors as regular refs.
      ok_put_ref(ref, acc, bld)
    else
      {:error, {:no_such_dynamic_anchor, _}} -> ok_put_ref(raw_ref, acc, bld)
      {:ok, %{dynamic?: false} = ref} -> ok_put_ref(ref, acc, bld)
    end
  end

  def take_keyword({"$dynamicAnchor", _anchor}, acc, bld, _) do
    {:ok, acc, bld}
  end

  consume_keyword("$comment")
  consume_keyword("$id")
  consume_keyword("$schema")
  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    list
  end

  def ok_put_ref(%Ref{} = ref, acc, bld) do
    bld = Builder.stage_build(bld, ref)
    {:ok, [{:ref, Key.of(ref)} | acc], bld}
  end

  def ok_put_ref(raw_ref, acc, bld) when is_binary(raw_ref) do
    with {:ok, ref} <- Ref.parse(raw_ref, bld.ns) do
      ok_put_ref(ref, acc, bld)
    end
  end

  # If the ref is a pointer but points to a schema with an $id we will swap the
  # ref to target that ID instead, so we can support skipping over boundaries
  # when resolving dynamic refs by not adding intermediary scopes.
  def maybe_swap_ref(%{kind: :pointer} = ref, bld) do
    with {:ok, bld} <- Builder.ensure_resolved(bld, ref),
         {:ok, resolved} <- Builder.fetch_resolved(bld, Key.of(ref)) do
      case resolved do
        %Resolved{raw: %{"$id" => _}, ns: ns} ->
          {:ok, new_ref} = Ref.parse(ns, :root)
          {:ok, new_ref, bld}

        _ ->
          {:ok, ref, bld}
      end
    end
  end

  def maybe_swap_ref(ref, bld) do
    {:ok, ref, bld}
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

  def validate(data, vds, vdr) do
    Validator.iterate(vds, data, vdr, &validate_keyword/3)
  end

  def validate_keyword({:ref, ref}, data, vdr) do
    Validator.validate_ref(data, ref, vdr)
  end

  # ---------------------------------------------------------------------------
end
