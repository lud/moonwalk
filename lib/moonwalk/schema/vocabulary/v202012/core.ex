defmodule Moonwalk.Schema.Vocabulary.V202012.Core do
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.BuildContext
  alias Moonwalk.Schema.Validator.Context
  alias Moonwalk.Schema.Ref
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords(~w(
    $anchor
    $comment
    $dynamicAnchor
    $dynamicRef
    $id
    $schema
  ))

  def take_keyword({"$ref", raw_ref}, acc, ctx) do
    with {:ok, ref} <- Ref.parse(raw_ref, ctx.ns) do
      ctx = BuildContext.stage_ref(ctx, ref)
      {:ok, [{:"$ref", ref} | acc], ctx}
    end
  end

  IO.warn("todo look for anchors")

  def take_keyword({"$defs", _defs}, acc, ctx) do
    {:ok, acc, ctx}
  end

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    list
  end

  # ---------------------------------------------------------------------------

  def validate(data, vds, ctx) do
    run_validators(data, vds, ctx, :validate_keyword)
  end

  defp validate_keyword(data, {:"$ref", ref}, ctx) do
    subvalidators = Context.checkout_ref(ctx, ref)
    Validator.validate_sub(data, subvalidators, ctx)
  end
end
