defmodule Moonwalk.Spec.ExternalDocumentation do
  require JSV
  use Moonwalk.Spec

  # Allows referencing an external resource for extended documentation.
  JSV.defschema(%{
    title: "ExternalDocumentation",
    type: :object,
    description: "Allows referencing an external resource for extended documentation.",
    properties: %{
      description: %{type: :string, description: "A description of the target documentation."},
      url: %{type: :string, description: "A URI for the target documentation. Required."}
    },
    required: [:url]
  })
end
