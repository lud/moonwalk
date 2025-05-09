defmodule Moonwalk.Spec.Parameter do
  require JSV
  use Moonwalk.Spec

  # Describes a single operation parameter.
  JSV.defschema(%{
    title: "Parameter",
    type: :object,
    description:
      "Describes a single operation parameter.",
    properties: %{
      name: %{
        type: :string,
        description: "The name of the parameter. Required."
      },
      in: %{
        type: :string,
        description: "The location of the parameter. Required."
      },
      description: %{type: :string, description: "A brief description of the parameter."},
      required: %{type: :boolean, description: "Determines whether this parameter is mandatory."},
      deprecated: %{type: :boolean, description: "Specifies that the parameter is deprecated."},
      allowEmptyValue: %{type: :boolean, description: "Sets the ability to pass empty-valued parameters."},
      style: %{type: :string, description: "Describes how the parameter value will be serialized."},
      explode: %{type: :boolean, description: "When true, array or object values generate separate parameters."},
      allowReserved: %{type: :boolean, description: "Allows reserved characters in parameter values."},
      schema: %{oneOf: [Moonwalk.Spec.SchemaWrapper, Moonwalk.Spec.Reference]},
      example: %{description: "An example of the parameter's potential value."},
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
        description: "Examples of the parameter's potential value."
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "A map containing parameter representations for different media types."
      }
    },
    required: [:name, :in]
  })
end
