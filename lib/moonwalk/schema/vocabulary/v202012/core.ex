defmodule Moonwalk.Schema.Vocabulary.V202012.Core do
  alias Moonwalk.Schema.Key
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Schema.Ref
  use Moonwalk.Schema.Vocabulary, priority: 100

  def init_validators(_) do
    []
  end

  def take_keyword({"$ref", raw_ref}, acc, bld) do
    with {:ok, ref} <- Ref.parse(raw_ref, bld.ns) |> dbg() do
      add_regular_ref(ref, acc, bld)
    end
  end

  def take_keyword({"$defs", _defs}, acc, bld) do
    {:ok, acc, bld}
  end

  def take_keyword({"$anchor", _anchor}, acc, bld) do
    {:ok, acc, bld}
  end

  def take_keyword({"$dynamicRef", raw_ref}, acc, bld) do
    # We need to ensure that the dynamic ref is in a schema where a
    # corresponding dynamic anchor is present. Otherwise we are just a normal
    # ref to an anchor (and we do not check its existence at this point.)

    with {:ok, %{dynamic?: true, kind: :anchor, arg: anchor} = ref} <- Ref.parse_dynamic(raw_ref, bld.ns),
         {:ok, bld} <- Builder.ensure_resolved(bld, ref),
         {:ok, %{raw: raw}} <- Builder.fetch_resolved(bld, ref.ns),
         :ok <- find_local_dynamic_anchor(raw, anchor) do
      bld = Builder.stage_build(bld, ref)
      # The "dynamic" information is carried in the key, so we just return a
      # :ref tuple. This allows to treat dynamic refs without anchors as regular
      # refs.
      {:ok, [{:ref, Key.of(ref)} | acc], bld}
    else
      {:error, {:no_such_dynamic_anchor, _}} -> add_regular_ref(raw_ref, acc, bld)
      {:ok, %{dynamic?: false} = ref} -> add_regular_ref(ref, acc, bld)
    end
  end

  def take_keyword({"$dynamicAnchor", _anchor}, acc, bld) do
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

  defp add_regular_ref(%Ref{} = ref, acc, bld) do
    bld = Builder.stage_build(bld, ref)
    {:ok, [{:ref, Key.of(ref)} | acc], bld}
  end

  defp add_regular_ref(raw_ref, acc, bld) when is_binary(raw_ref) do
    with {:ok, ref} <- Ref.parse(raw_ref, bld.ns) do
      add_regular_ref(ref, acc, bld)
    end
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
