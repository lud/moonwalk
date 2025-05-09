defmodule Moonwalk.Spec.Response do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Response",
    type: :object,
    properties: %{
      description: %{type: :string, description: "Description"},
      headers: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Header, Moonwalk.Spec.Reference]},
        description: "Headers"
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "Content"
      },
      links: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Link, Moonwalk.Spec.Reference]},
        description: "Links"
      }
    },
    required: [:description]
  })
end
