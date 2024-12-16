defmodule JSV.Key do
  alias JSV.Ref

  def of(binary) when is_binary(binary) do
    binary
  end

  def of(:root) do
    :root
  end

  def of(%Ref{} = ref) do
    of_ref(ref)
  end

  def of({:dynamic_anchor, _, _} = key) do
    key
  end

  defp of_ref(%{dynamic?: true, ns: ns, kind: :anchor} = ref) do
    %{arg: arg} = ref
    for_dynamic_anchor(ns, arg)
  end

  defp of_ref(%{dynamic?: false} = ref) do
    %Ref{kind: kind, ns: ns, arg: arg} = ref

    case kind do
      :top -> ns
      :pointer -> for_pointer(ns, arg)
      :anchor -> for_anchor(ns, arg)
    end
  end

  def for_pointer(ns, arg) do
    {:pointer, ns, arg}
  end

  def for_anchor(ns, arg) do
    {:anchor, ns, arg}
  end

  def for_dynamic_anchor(ns, arg) do
    {:dynamic_anchor, ns, arg}
  end

  def namespace_of(binary) when is_binary(binary) do
    binary
  end

  def namespace_of(:root) do
    :root
  end

  def namespace_of({:anchor, ns, _}) do
    ns
  end

  def namespace_of({:dynamic_anchor, ns, _}) do
    ns
  end

  def namespace_of({:pointer, ns, _}) do
    ns
  end
end
