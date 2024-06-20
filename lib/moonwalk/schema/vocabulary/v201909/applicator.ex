defmodule Moonwalk.Schema.Vocabulary.V201909.Applicator do
  alias Moonwalk.Schema.Vocabulary.V202012.Applicator, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 200

  @impl true
  defdelegate init_validators(opts), to: Fallback
  @impl true
  defdelegate take_keyword(kw_tuple, acc, ctx), to: Fallback
  @impl true
  defdelegate finalize_validators(acc), to: Fallback
  @impl true
  defdelegate validate(data, vds, vdr), to: Fallback
end
