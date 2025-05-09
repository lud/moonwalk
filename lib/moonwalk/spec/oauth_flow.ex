defmodule Moonwalk.Spec.OAuthFlow do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "OAuthFlow",
    type: :object,
    properties: %{
      authorizationUrl: %{type: :string, description: "Authorization URL"},
      tokenUrl: %{type: :string, description: "Token URL"},
      refreshUrl: %{type: :string, description: "Refresh URL"},
      scopes: %{type: :object, additionalProperties: %{type: :string}, description: "Scopes"}
    },
    required: [:scopes]
  })
end
