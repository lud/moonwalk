defmodule Moonwalk.Spec.Operation do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Operation",
    type: :object,
    properties: %{
      tags: %{type: :array, items: %{type: :string}, description: "Tags"},
      summary: %{type: :string, description: "Summary"},
      description: %{type: :string, description: "Description"},
      externalDocs: Moonwalk.Spec.ExternalDocumentation,
      operationId: %{type: :string, description: "Operation ID"},
      parameters: %{
        type: :array,
        items: %{oneOf: [Moonwalk.Spec.Parameter, Moonwalk.Spec.Reference]},
        description: "Parameters"
      },
      requestBody: %{oneOf: [Moonwalk.Spec.RequestBody, Moonwalk.Spec.Reference]},
      responses: Moonwalk.Spec.Responses,
      callbacks: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Callback, Moonwalk.Spec.Reference]},
        description: "Callbacks"
      },
      deprecated: %{type: :boolean, description: "Deprecated"},
      security: %{type: :array, items: Moonwalk.Spec.SecurityRequirement, description: "Security"},
      servers: %{type: :array, items: Moonwalk.Spec.Server, description: "Servers"}
    },
    required: [:responses]
  })
end
