defmodule Moonwalk.Spec.Link do
  require JSV
  use Moonwalk.Internal.SpecObject

  JSV.defschema(%{
    title: "Link",
    type: :object,
    description: "Represents a possible design-time link for a response.",
    properties: %{
      operationRef: %{type: :string, description: "Operation reference"},
      operationId: %{type: :string, description: "Operation ID"},
      parameters: %{
        type: :object,
        additionalProperties: %{description: "Parameter value"},
        description: "Parameters"
      },
      requestBody: %{description: "Request body"},
      description: %{type: :string, description: "Description"},
      server: Moonwalk.Spec.Server
    },
    required: []
  })
end
