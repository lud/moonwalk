defmodule Moonwalk.Spec.ExternalDocumentation do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "ExternalDocumentation",
    type: :object,
    properties: %{
      description: %{type: :string, description: "Description"},
      url: %{type: :string, description: "URL"}
    },
    required: [:url]
  })
end
