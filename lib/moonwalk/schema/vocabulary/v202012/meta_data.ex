defmodule Moonwalk.Schema.Vocabulary.V202012.MetaData do
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords(~w(
    title
    description
    default
    deprecated
    readOnly
    writeOnly
    examples
  ))

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    Map.new(list)
  end
end
