defmodule Moonwalk do
  alias Moonwalk.Spec.Api

  def normalize_spec(%Api{} = api) do
    Api.normalize_spec(api)
  end
end
