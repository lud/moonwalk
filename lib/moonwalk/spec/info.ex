defmodule Moonwalk.Spec.Info do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "Info",
    type: :object,
    properties: %{
      title: %{type: :string, description: "API title"},
      summary: %{type: :string, description: "API summary"},
      description: %{type: :string, description: "API description"},
      termsOfService: %{type: :string, description: "Terms of service URL"},
      contact: Moonwalk.Spec.Contact,
      license: Moonwalk.Spec.License,
      version: %{type: :string, description: "API version"}
    },
    required: [:title, :version]
  })
end
