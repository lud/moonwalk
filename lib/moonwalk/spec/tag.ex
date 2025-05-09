defmodule Moonwalk.Spec.Tag do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Tag",
    type: :object,
    properties: %{
      name: %{type: :string, description: "Tag name"},
      description: %{type: :string, description: "Description"},
      externalDocs: Moonwalk.Spec.ExternalDocumentation
    },
    required: [:name]
  })
end
