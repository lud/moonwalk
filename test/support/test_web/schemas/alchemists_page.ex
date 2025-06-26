defmodule Moonwalk.TestWeb.Schemas.AlchemistsPage do
  alias Moonwalk.TestWeb.Schemas.Alchemist

  require(JSV).defschema(%{
    type: :object,
    properties: %{
      data: %{type: :array, items: Alchemist}
    },
    required: [:data]
  })
end
