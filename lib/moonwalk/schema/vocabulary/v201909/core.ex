defmodule Moonwalk.Schema.Vocabulary.V201909.Core do
  alias Moonwalk.Schema.Vocabulary.V202012.Core, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 300

  @impl true
  defdelegate init_validators(opts), to: Fallback


  @impl true
  defdelegate finalize_validators(acc), to: Fallback

  @impl true
  defdelegate validate(data, vds, vdr), to: Fallback


  @impl true


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

  defdelegate take_keyword(kw_tuple, acc, ctx), to: Fallback
end
