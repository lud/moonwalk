defmodule Moonwalk.Spec.Tag do
  require JSV
  use Moonwalk.Spec

  # Adds metadata to a single tag.
  JSV.defschema(%{
    title: "Tag",
    type: :object,
    description: "Adds metadata to a single tag.",
    properties: %{
      name: %{type: :string, description: "The name of the tag. Required."},
      description: %{type: :string, description: "A description for the tag."},
      externalDocs: Moonwalk.Spec.ExternalDocumentation
    },
    required: [:name]
  })
end
