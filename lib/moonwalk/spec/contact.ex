defmodule Moonwalk.Spec.Contact do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Contact",
    type: :object,
    properties: %{
      name: %{type: :string, description: "Contact name"},
      url: %{type: :string, description: "Contact URL"},
      email: %{type: :string, description: "Contact email"}
    },
    required: []
  })
end
