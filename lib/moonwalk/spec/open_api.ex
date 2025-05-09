defmodule Moonwalk.Spec.OpenAPI do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "OpenAPI",
    type: :object,
    properties: %{
      openapi: %{type: :string, description: "OpenAPI version"},
      info: Moonwalk.Spec.Info,
      jsonSchemaDialect: %{type: :string, description: "Default $schema for JSON Schema"},
      servers: %{type: :array, items: Moonwalk.Spec.Server, description: "API servers"},
      paths: Moonwalk.Spec.Paths,
      webhooks: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.PathItem,
        description: "Webhooks"
      },
      components: Moonwalk.Spec.Components,
      security: %{
        type: :array,
        items: Moonwalk.Spec.SecurityRequirement,
        description: "Security requirements"
      },
      tags: %{type: :array, items: Moonwalk.Spec.Tag, description: "Tags"},
      externalDocs: Moonwalk.Spec.ExternalDocumentation
    },
    required: [:openapi, :info, :paths]
  })
end
