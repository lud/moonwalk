defmodule Moonwalk.Spec.Reference do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "Reference",
    type: :object,
    properties: %{
      "$ref": %{type: :string, description: "Reference"},
      summary: %{type: :string, description: "Summary"},
      description: %{type: :string, description: "Description"}
    },
    required: [:"$ref"]
  })
end
