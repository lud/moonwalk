defmodule Moonwalk.Spec.Reference do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Allows referencing other components in the OpenAPI Description.
  JSV.defschema(%{
    title: "Reference",
    type: :object,
    description:
      "Allows referencing other components in the OpenAPI Description using a URI, with optional summary and description overrides.",
    properties: %{
      "$ref": %{
        type: :string,
        description: "Reference identifier in the form of a URI. Required."
      },
      summary: %{
        type: :string,
        description: "A summary that should override the referenced component's summary."
      },
      description: %{
        type: :string,
        description: "A description that should override the referenced component's description."
      }
    },
    additionalProperties: false,
    required: [:"$ref"]
  })
end
