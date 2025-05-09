defmodule Moonwalk.Spec.Discriminator do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Discriminator",
    type: :object,
    properties: %{
      propertyName: %{type: :string, description: "Discriminator property"},
      mapping: %{type: :object, additionalProperties: %{type: :string}, description: "Mapping"}
    },
    required: [:propertyName]
  })
end
