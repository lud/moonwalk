defmodule Moonwalk.Spec.OAuthFlows do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Configures supported OAuth Flows for a security scheme.
  JSV.defschema(%{
    title: "OAuthFlows",
    type: :object,
    description: "Configures supported OAuth Flows for a security scheme.",
    properties: %{
      implicit: Moonwalk.Spec.OAuthFlow,
      password: Moonwalk.Spec.OAuthFlow,
      clientCredentials: Moonwalk.Spec.OAuthFlow,
      authorizationCode: Moonwalk.Spec.OAuthFlow
    },
    required: []
  })
end
