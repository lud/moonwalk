defmodule Moonwalk.Schema.Vocabulary.V202012.Unevaluated do
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords(~w(
    unevaluatedItems
    unevaluatedProperties
  ))

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    Map.new(list)
  end

  def validate(_data, _validators, _context) do
    raise "TODO!"
  end
end
