defmodule Moonwalk.Spec.Encoding do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "Encoding",
    type: :object,
    description: "A single encoding definition applied to a single schema property.",
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
