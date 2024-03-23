defmodule Moonwalk.Schema.Key do
  alias Moonwalk.Schema.Ref

  def of(binary) when is_binary(binary) do
    binary
  end

  def of(:root) do
    :root
  end

  def of(%Ref{} = ref) do
    of_ref(ref)
  end

  defp of_ref(%{dynamic?: true, ns: ns, kind: :anchor} = ref) do
    %{fragment: fragment} = ref
    {:dynamic_anchor, ns, fragment}
  end

  defp of_ref(ref) do
    %Ref{kind: kind, ns: ns, fragment: fragment} = ref

    case kind do
      :top -> ns
      :docpath -> for_pointer(ns, fragment)
      :anchor -> for_anchor(ns, fragment)
    end
  end

  def for_pointer(ns, fragment) do
    {:pointer, ns, fragment}
  end

  def for_anchor(ns, fragment) do
    {:anchor, ns, fragment}
  end

  def for_dynamic_anchor(ns, fragment) do
    {:dynamic_anchor, ns, fragment}
  end

  def namespace_of(binary) when is_binary(binary) do
    binary
  end

  def namespace_of(:root) do
    :root
  end

  def namespace_of(%Ref{ns: ns}) do
    ns
  end
end
