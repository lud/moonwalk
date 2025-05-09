defmodule Moonwalk.Spec.Example do
  import JSV
  use Moonwalk.Spec

  defschema(%{
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
