defmodule Moonwalk.Spec.Reference do
  import JSV
  use Moonwalk.Spec

  defschema(%{
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
