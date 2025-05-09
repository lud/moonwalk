defmodule Moonwalk.Spec.SecurityScheme do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "SecurityScheme",
    type: :object,
    properties: %{
      type: %{type: :string, description: "Security scheme type"},
      description: %{type: :string, description: "Description"},
      name: %{type: :string, description: "Parameter name"},
      in: %{type: :string, description: "Parameter location"},
      scheme: %{type: :string, description: "HTTP scheme"},
      bearerFormat: %{type: :string, description: "Bearer format"},
      flows: Moonwalk.Spec.OAuthFlows,
      openIdConnectUrl: %{type: :string, description: "OpenID Connect URL"}
    },
    required: [:type]
  })
end
