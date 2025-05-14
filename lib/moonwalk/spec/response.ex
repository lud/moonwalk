defmodule Moonwalk.Spec.Response do
  require JSV
  use Moonwalk.Spec

  # Describes a single response from an API operation.
  JSV.defschema(%{
    title: "Response",
    type: :object,
    description: "Describes a single response from an API operation.",
    properties: %{
      description: %{type: :string, description: "A description of the response. Required."},
      headers: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Header, Moonwalk.Spec.Reference]},
        description: "A map of header names to their definitions."
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "A map of potential response payloads by media type."
      },
      links: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Link, Moonwalk.Spec.Reference]},
        description: "A map of operation links that can be followed from the response."
      }
    },
    required: [:description]
  })
end
