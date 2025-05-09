defmodule Moonwalk.Spec.Example do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "Example",
    type: :object,
    properties: %{
      summary: %{type: :string, description: "Summary"},
      description: %{type: :string, description: "Description"},
      value: %{description: "Value"},
      externalValue: %{type: :string, description: "External value"}
    },
    required: []
  })
end
