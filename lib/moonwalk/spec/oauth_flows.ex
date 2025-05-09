defmodule Moonwalk.Spec.OAuthFlows do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "OAuthFlows",
    type: :object,
    properties: %{
      implicit: Moonwalk.Spec.OAuthFlow,
      password: Moonwalk.Spec.OAuthFlow,
      clientCredentials: Moonwalk.Spec.OAuthFlow,
      authorizationCode: Moonwalk.Spec.OAuthFlow
    },
    required: []
  })
end
