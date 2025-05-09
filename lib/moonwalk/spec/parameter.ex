defmodule Moonwalk.Spec.Parameter do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Parameter",
    type: :object,
    properties: %{
      name: %{type: :string, description: "Parameter name"},
      in: %{type: :string, description: "Parameter location"},
      description: %{type: :string, description: "Description"},
      required: %{type: :boolean, description: "Required"},
      deprecated: %{type: :boolean, description: "Deprecated"},
      allowEmptyValue: %{type: :boolean, description: "Allow empty value"},
      style: %{type: :string, description: "Style"},
      explode: %{type: :boolean, description: "Explode"},
      allowReserved: %{type: :boolean, description: "Allow reserved"},
      schema: Moonwalk.Spec.Schema,
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
    required: [:name, :in]
  })
end
