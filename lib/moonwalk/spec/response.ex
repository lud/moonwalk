defmodule Moonwalk.Spec.Response do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Describes a single response from an API operation.
  JSV.defschema(%{
    title: "Response",
    type: :object,
    description: "Describes a single response from an API operation.",
    properties: %{
      description: %{type: :string, description: "A description of the response. Required."},
      headers: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Header]},
        description: "A map of header names to their definitions."
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "A map of potential response payloads by media type."
      },
      links: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Link]},
        description: "A map of operation links that can be followed from the response."
      }
    },
    required: [:description]
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default([:description])
    |> normalize_subs(
      headers: {:map, {:or_ref, Moonwalk.Spec.Header}},
      content: {:map, Moonwalk.Spec.MediaType},
      links: {:map, {:or_ref, Moonwalk.Spec.Link}}
    )
    |> collect()
  end
end
