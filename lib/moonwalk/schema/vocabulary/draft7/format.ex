defmodule Moonwalk.Schema.Vocabulary.Draft7.Format do
  alias Moonwalk.Schema.Vocabulary.V202012.Format, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 300

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true
  defdelegate take_keyword(kw_tuple, acc, ctx, raw_schema), to: Fallback

  @impl true
  defdelegate finalize_validators(acc), to: Fallback

  @impl true
  defdelegate validate(data, vds, vdr), to: Fallback
end
