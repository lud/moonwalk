defmodule Moonwalk.Spec.XML do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "XML",
    type: :object,
    properties: %{
      name: %{type: :string, description: "Element/attribute name"},
      namespace: %{type: :string, description: "Namespace"},
      prefix: %{type: :string, description: "Prefix"},
      attribute: %{type: :boolean, description: "Is attribute"},
      wrapped: %{type: :boolean, description: "Is wrapped"}
    },
    required: []
  })
end
