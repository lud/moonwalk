defmodule Moonwalk.Spec.Components do
  require JSV
  use Moonwalk.Internal.SpecObject

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

  @impl true
  def normalize!(data, ctx) do
    data
    |> from(__MODULE__, ctx)
    # Schemas are handled at the top level when initializing the context
    |> skip(:schemas)
    |> normalize_subs(
      responses: {:map, Moonwalk.Spec.Response},
      parameters: {:map, Moonwalk.Spec.Parameter},
      examples: {:map, Moonwalk.Spec.Example},
      requestBodies: {:map, Moonwalk.Spec.RequestBody},
      headers: {:map, Moonwalk.Spec.Header},
      securitySchemes: {:map, Moonwalk.Spec.SecurityScheme},
      links: {:map, Moonwalk.Spec.Link},
      callbacks: {:map, Moonwalk.Spec.Callback},
      pathItems: {:map, Moonwalk.Spec.PathItem}
    )
    |> collect()
  end
end
