defmodule Moonwalk.Spec.ServerVariable do
  import JSV
  use Moonwalk.Spec
  alias JSV.Schema

  defschema(%{
    title: "ServerVariable",
    type: :object,
    properties: %{
      enum: %{type: :array, items: %{type: :string}, description: "Allowed values"},
      default: %{type: :string, description: "Default value"},
      description: %{type: :string, description: "Variable description"}
    },
    required: [:default]
  })
end
