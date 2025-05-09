defmodule Moonwalk.Spec.PathItem do
  require JSV
  use Moonwalk.Spec

  # Describes operations available on a single path.
  JSV.defschema(%{
    title: "PathItem",
    type: :object,
    description: "Describes operations available on a single path.",
    properties: %{
      "$ref": %{
        type: :string,
        description: "Allows for a referenced definition of this path item."
      },
      summary: %{
        type: :string,
        description: "An optional string summary for all operations in this path."
      },
      description: %{
        type: :string,
        description: "An optional string description for all operations in this path."
      },
      get: Moonwalk.Spec.Operation,
      put: Moonwalk.Spec.Operation,
      post: Moonwalk.Spec.Operation,
      delete: Moonwalk.Spec.Operation,
      options: Moonwalk.Spec.Operation,
      head: Moonwalk.Spec.Operation,
      patch: Moonwalk.Spec.Operation,
      trace: Moonwalk.Spec.Operation,
      servers: %{
        type: :array,
        items: Moonwalk.Spec.Server,
        description: "Alternative servers array for all operations in this path."
      },
      parameters: %{
        type: :array,
        items: %{oneOf: [Moonwalk.Spec.Parameter, Moonwalk.Spec.Reference]},
        description: "Parameters applicable for all operations under this path."
      }
    },
    required: []
  })
end
