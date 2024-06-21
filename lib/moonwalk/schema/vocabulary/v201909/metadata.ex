defmodule Moonwalk.Schema.Vocabulary.VDraft7.MetaData do
  alias Moonwalk.Schema.Vocabulary.V202012.MetaData, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 300

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true
  defdelegate take_keyword(kw_tuple, acc, ctx), to: Fallback

  @impl true
  defdelegate finalize_validators(acc), to: Fallback

  @impl true
  def validate(_data, _validators, _context) do
    raise "should not be called"
  end
end
