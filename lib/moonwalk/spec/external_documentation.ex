defmodule Moonwalk.Spec.ExternalDocumentation do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "ExternalDocumentation",
    type: :object,
    properties: %{
      description: %{type: :string, description: "Description"},
      url: %{type: :string, description: "URL"}
    },
    required: [:url]
  })
end
