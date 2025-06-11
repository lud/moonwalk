defmodule Moonwalk.Spec.Discriminator do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Provides a hint about the expected schema when request bodies or responses may be one of several schemas.
  JSV.defschema(%{
    title: "Discriminator",
    type: :object,
    description:
      "Provides a hint about the expected schema when request bodies or responses may be one of several schemas, using a property name and optional mapping.",
    properties: %{
      propertyName: %{
        type: :string,
        description: "The name of the property in the payload with the discriminating value. Required."
      },
      mapping: %{
        type: :object,
        additionalProperties: %{type: :string},
        description: "Mappings between payload values and schema names or URI references."
      }
    },
    required: [:propertyName]
  })
end
