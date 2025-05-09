defmodule Moonwalk.Spec.Components do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "Components",
    type: :object,
    properties: %{
      schemas: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.SchemaWrapper,
        description: "Schemas"
      },
      responses: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]},
        description: "Responses"
      },
      parameters: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Parameter, Moonwalk.Spec.Reference]},
        description: "Parameters"
      },
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
        description: "Examples"
      },
      requestBodies: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.RequestBody, Moonwalk.Spec.Reference]},
        description: "Request bodies"
      },
      headers: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Header, Moonwalk.Spec.Reference]},
        description: "Headers"
      },
      securitySchemes: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.SecurityScheme, Moonwalk.Spec.Reference]},
        description: "Security schemes"
      },
      links: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Link, Moonwalk.Spec.Reference]},
        description: "Links"
      },
      callbacks: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Callback, Moonwalk.Spec.Reference]},
        description: "Callbacks"
      },
      pathItems: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.PathItem,
        description: "Path items"
      }
    },
    required: []
  })
end
