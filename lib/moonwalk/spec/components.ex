defmodule Moonwalk.Spec.Components do
  require JSV
  use Moonwalk.Internal.Normalizer

  IO.warn("We need to be able to build operations from any referenced component")

  # Holds reusable objects for different aspects of the OpenAPI Specification.
  JSV.defschema(%{
    title: "Components",
    type: :object,
    description:
      "Holds reusable objects for different aspects of the OpenAPI Specification, such as schemas, responses, parameters, and more.",
    properties: %{
      schemas: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.SchemaWrapper,
        description: "A map of reusable Schema Objects."
      },
      responses: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Response,
        description: "A map of reusable Response Objects or Reference Objects."
      },
      parameters: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Parameter,
        description: "A map of reusable Parameter Objects or Reference Objects."
      },
      examples: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Example,
        description: "A map of reusable Example Objects or Reference Objects."
      },
      requestBodies: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.RequestBody,
        description: "A map of reusable Request Body Objects or Reference Objects."
      },
      headers: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Header,
        description: "A map of reusable Header Objects or Reference Objects."
      },
      securitySchemes: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.SecurityScheme,
        description: "A map of reusable Security Scheme Objects or Reference Objects."
      },
      links: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Link,
        description: "A map of reusable Link Objects or Reference Objects."
      },
      callbacks: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Callback,
        description: "A map of reusable Callback Objects or Reference Objects."
      },
      pathItems: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.PathItem,
        description: "A map of reusable Path Item Objects."
      }
    },
    required: []
  })
end
