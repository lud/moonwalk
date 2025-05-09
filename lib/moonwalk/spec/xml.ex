defmodule Moonwalk.Spec.XML do
  require JSV
  use Moonwalk.Spec

  # Metadata for fine-tuned XML model definitions.
  JSV.defschema(%{
    title: "XML",
    type: :object,
    description: "Metadata for fine-tuned XML model definitions.",
    properties: %{
      name: %{
        type: :string,
        description: "Replaces the name of the element or attribute used for the schema property."
      },
      namespace: %{type: :string, description: "A URI of the namespace definition."},
      prefix: %{type: :string, description: "A prefix to be used for the name."},
      attribute: %{
        type: :boolean,
        description: "Whether the property translates to an attribute instead of an element."
      },
      wrapped: %{
        type: :boolean,
        description: "Whether the array is wrapped (for array definitions only)."
      }
    },
    required: []
  })
end
