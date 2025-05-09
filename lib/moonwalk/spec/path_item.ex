defmodule Moonwalk.Spec.PathItem do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "PathItem",
    type: :object,
    properties: %{
      "$ref": %{type: :string, description: "Reference"},
      summary: %{type: :string, description: "Summary"},
      description: %{type: :string, description: "Description"},
      get: Moonwalk.Spec.Operation,
      put: Moonwalk.Spec.Operation,
      post: Moonwalk.Spec.Operation,
      delete: Moonwalk.Spec.Operation,
      options: Moonwalk.Spec.Operation,
      head: Moonwalk.Spec.Operation,
      patch: Moonwalk.Spec.Operation,
      trace: Moonwalk.Spec.Operation,
      servers: %{type: :array, items: Moonwalk.Spec.Server, description: "Servers"},
      parameters: %{
        type: :array,
        items: %{oneOf: [Moonwalk.Spec.Parameter, Moonwalk.Spec.Reference]},
        description: "Parameters"
      }
    },
    required: []
  })
end
