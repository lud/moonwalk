defmodule Moonwalk.Spec.License do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "License",
    type: :object,
    properties: %{
      name: %{type: :string, description: "License name"},
      identifier: %{type: :string, description: "SPDX identifier"},
      url: %{type: :string, description: "License URL"}
    },
    required: [:name]
  })
end
