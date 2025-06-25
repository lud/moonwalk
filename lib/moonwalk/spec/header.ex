defmodule Moonwalk.Spec.Header do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Describes a single header.
  JSV.defschema(%{
    title: "Header",
    type: :object,
    description: "Describes a single header.",
    properties: %{
      description: %{type: :string, description: "A brief description of the header."},
      required: %{type: :boolean, description: "Determines whether this header is mandatory."},
      deprecated: %{type: :boolean, description: "Specifies that the header is deprecated."},
      style:
        JSV.Schema.string_to_atom_enum(
          %{
            description: "Describes how the header value will be serialized. Default and only legal value is 'simple'."
          },
          [
            :simple
          ]
        ),
      explode: %{
        type: :boolean,
        description: "When true, array or object values generate a comma-separated list."
      },
      schema: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.SchemaWrapper]},
      example: %{description: "An example of the header's potential value."},
      examples: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Example]},
        description: "Examples of the header's potential value."
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "A map containing header representations for different media types."
      }
    },
    required: []
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> from(__MODULE__, ctx)
    |> normalize_default([
      :description,
      :required,
      :deprecated,
      :style,
      :explode,
      :example,
      :examples
    ])
    |> normalize_schema(:schema)
    |> normalize_subs(content: {:map, Moonwalk.Spec.MediaType})
    |> collect()
  end
end
