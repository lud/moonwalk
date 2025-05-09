defmodule Moonwalk.Spec.Encoding do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Encoding",
    type: :object,
    properties: %{
      contentType: %{type: :string, description: "Content type"},
      headers: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Header, Moonwalk.Spec.Reference]},
        description: "Headers"
      },
      style: %{type: :string, description: "Style"},
      explode: %{type: :boolean, description: "Explode"},
      allowReserved: %{type: :boolean, description: "Allow reserved"}
    },
    required: []
  })
end
