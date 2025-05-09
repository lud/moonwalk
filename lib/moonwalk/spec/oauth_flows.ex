defmodule Moonwalk.Spec.OAuthFlows do
  import JSV
  use Moonwalk.Spec

  defschema(%{
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
