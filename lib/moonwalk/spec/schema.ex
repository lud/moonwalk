defmodule Moonwalk.Spec.Schema do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Schema",
    type: :object,
    properties: %{
      discriminator: Moonwalk.Spec.Discriminator,
      xml: Moonwalk.Spec.XML,
      externalDocs: Moonwalk.Spec.ExternalDocumentation,
      example: %{description: "Example"}
    },
    required: []
  })
end
