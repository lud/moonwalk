defmodule Moonwalk.Spec.MediaType do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "MediaType",
    type: :object,
    properties: %{
      schema: Moonwalk.Spec.Schema,
      example: %{description: "Example"},
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
        description: "Examples"
      },
      encoding: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Encoding,
        description: "Encoding"
      }
    },
    required: []
  })
end
