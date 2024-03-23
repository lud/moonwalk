defmodule Moonwalk.Schema.Vocabulary.V202012.Core do
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.Resolver
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Schema.Validator.Context
  alias Moonwalk.Schema.Ref
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  def take_keyword({"$ref", raw_ref}, acc, ctx) do
    with {:ok, ref} <- Ref.parse(raw_ref, ctx.ns) do
      {validator_ref, ctx} = Builder.stage_build(ctx, ref)
      {:ok, [{:ref, validator_ref} | acc], ctx}
    end
  end

  def take_keyword({"$defs", _defs}, acc, ctx) do
    {:ok, acc, ctx}
  end

  def take_keyword({"$anchor", _anchor}, acc, ctx) do
    {:ok, acc, ctx}
  end

  def take_keyword({"$dynamicRef", raw_ref}, acc, ctx) do
    with {:ok, ref} <- Ref.parse_dynamic(raw_ref, ctx.ns) do
      {validator_ref, ctx} = Builder.stage_build(ctx, ref)

      {:ok, [{:dynamic_ref, validator_ref} | acc], ctx}
    end
  end

  def take_keyword({"$dynamicAnchor", _anchor}, acc, ctx) do
    {:ok, acc, ctx}
  end

  skip_keyword("$comment")
  skip_keyword("$id")
  skip_keyword("$schema")
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

  defp validate_keyword(data, {:ref, ref}, ctx) do
    subvalidators = Context.checkout_ref(ctx, ref)
    Validator.validate_sub(data, subvalidators, ctx)
  end

  defp validate_keyword(data, {:dynamic_ref, ref}, ctx) do
    subvalidators = Context.checkout_ref(ctx, ref)
    Validator.validate_sub(data, subvalidators, ctx)
  end
end
