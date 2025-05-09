defmodule Moonwalk.Spec.Server do
  import JSV
  use Moonwalk.Spec

  defschema(%{
    title: "Server",
    type: :object,
    properties: %{
      url: %{type: :string, description: "Server URL"},
      description: %{type: :string, description: "Server description"},
      variables: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.ServerVariable,
        description: "Server variables"
      }
    },
    required: [:url]
  })
end
