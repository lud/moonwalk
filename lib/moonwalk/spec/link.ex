defmodule Moonwalk.Spec.Link do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Link",
    type: :object,
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
