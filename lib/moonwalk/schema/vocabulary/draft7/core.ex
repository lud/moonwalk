defmodule Moonwalk.Schema.Vocabulary.Draft7.Core do
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Vocabulary.V202012.Core, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 300

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true

  def take_keyword({"$ref", raw_ref}, acc, bld, raw_schema) do
    this_schema_id = Map.get(raw_schema, "$id")

    # The ref is not relative to the $id if defined at the same level

    ref_relative_to_ns =
      case {raw_schema, bld} do
        {%{"$id" => current_id}, %{ns: current_id, parent_nss: [parent | _]}} ->
          parent

        {%{"$id" => current_id}, %{ns: current_id, parent_nss: []}} ->
          raise "Unsupported $id and $reference at the same level without higher level $id"

        {_, %{ns: parent_ns}} ->
          parent_ns
      end

    with {:ok, ref} <- Ref.parse(raw_ref, ref_relative_to_ns) do
      Fallback.ok_put_ref(ref, acc, bld)
    end
  end

  defdelegate take_keyword(kw_tuple, acc, ctx, raw_schema), to: Fallback

  @impl true
  defdelegate finalize_validators(acc), to: Fallback

  @impl true
  defdelegate validate(data, vds, vdr), to: Fallback
end
