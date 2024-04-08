defmodule Moonwalk.Schema.Vocabulary.V202012.Content do
  use Moonwalk.Schema.Vocabulary, priority: 300

  def init_validators do
    []
  end

  def take_keyword({"contentMediaType", _}, acc, ctx) do
    {:ok, acc, ctx}
  end

  def take_keyword({"contentEncoding", _}, acc, ctx) do
    {:ok, acc, ctx}
  end

  def take_keyword({"contentSchema", _}, acc, ctx) do
    {:ok, acc, ctx}
  end

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def validate(_data, _validators, _context) do
    raise "TODO!"
  end
end
