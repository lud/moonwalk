defmodule Moonwalk.Schema.Vocabulary.V202012.Format do
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  def take_keyword({"format", format}, acc, ctx) do
    {:ok, [{:format, format} | acc], ctx}
  end

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    Map.new(list)
  end

  def validate(data, vds, ctx) do
    run_validators(data, vds, ctx, :validate_keyword)
  end

  defp validate_keyword(data, {:format, format}, ctx) do
    IO.warn("todo acutal validation")
    {:ok, data}
  end
end
