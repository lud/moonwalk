defmodule Moonwalk.Schema.Vocabulary.V202012.MetaData do
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  skip_keyword("deprecated")
  skip_keyword("description")
  skip_keyword("default")
  skip_keyword("title")
  skip_keyword("readOnly")
  skip_keyword("writeOnly")
  skip_keyword("examples")

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    Map.new(list)
  end

  def validate(_data, _validators, _context) do
    raise "should not be called"
  end
end
