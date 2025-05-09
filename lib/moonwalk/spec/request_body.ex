defmodule Moonwalk.Spec.RequestBody do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "RequestBody",
    type: :object,
    properties: %{
      description: %{type: :string, description: "Description"},
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "Content"
      },
      required: %{type: :boolean, description: "Required"}
    },
    required: [:content]
  })
end
