defmodule Moonwalk.Spec.OpenAPI do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Root object describing the entire OpenAPI document and its structure.
  JSV.defschema(%{
    title: "OpenAPI",
    type: :object,
    description: "Root object of the OpenAPI description, containing metadata, paths, components, and more.",
    properties: %{
      openapi: %{
        type: :string,
        description: "The version number of the OpenAPI Specification used in this document. Required."
      },
      info: Moonwalk.Spec.Info,
      jsonSchemaDialect: %{
        type: :string,
        description: "The default value for the $schema keyword within Schema Objects."
      },
      servers: %{
        type: :array,
        items: Moonwalk.Spec.Server,
        description: "An array of Server Objects providing connectivity information to the API."
      },
      paths: Moonwalk.Spec.Paths,
      webhooks: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.PathItem,
        description: "A map of incoming webhooks that may be received as part of this API."
      },
      components: Moonwalk.Spec.Components,
      security: %{
        type: :array,
        items: Moonwalk.Spec.SecurityRequirement,
        description: "A list of security mechanisms that can be used across the API."
      },
      tags: %{
        type: :array,
        items: Moonwalk.Spec.Tag,
        description: "A list of tags used by the OpenAPI description with additional metadata."
      },
      externalDocs: Moonwalk.Spec.ExternalDocumentation
    },
    required: [:openapi, :info, :paths]
  })

  IO.warn("todo do not delete components")

  @impl true
  def normalize!(data, ctx) do
    data
    |> Map.drop([:components, "components"])
    |> make(__MODULE__, ctx)
    |> normalize_subs(
      openapi: :default,
      info: Moonwalk.Spec.Info,
      paths: Moonwalk.Spec.Paths,
      externalDocs: Moonwalk.Spec.ExternalDocumentation,
      servers: {:list, Moonwalk.Spec.Server},
      tags: {:list, Moonwalk.Spec.Tag}
    )
    |> collect()
  end
end
