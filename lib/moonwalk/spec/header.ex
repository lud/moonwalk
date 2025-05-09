defmodule Moonwalk.Spec.Header do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Header",
    type: :object,
    properties: %{
      description: %{type: :string, description: "Description"},
      required: %{type: :boolean, description: "Required"},
      deprecated: %{type: :boolean, description: "Deprecated"},
      style: %{type: :string, description: "Style"},
      explode: %{type: :boolean, description: "Explode"},
      schema: %{oneOf: [Moonwalk.Spec.Schema, Moonwalk.Spec.Reference]},
      example: %{description: "Example"},
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
        description: "Examples"
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "Content"
      }
    },
    required: []
  })
end
