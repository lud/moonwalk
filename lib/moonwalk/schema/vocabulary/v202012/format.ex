defmodule Moonwalk.Schema.Vocabulary.V202012.Format do
  use Moonwalk.Schema.Vocabulary, priority: 300

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

  def validate(data, vds, vdr) do
    run_validators(data, vds, vdr, &validate_keyword/3)
  end



  defp validate_keyword(data, {:format, _format}, vdr) do
    {:ok, data, vdr}
  end
end
