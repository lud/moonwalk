defmodule Moonwalk.Spec.SecurityScheme do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Defines a security scheme for operations.
  JSV.defschema(%{
    title: "SecurityScheme",
    type: :object,
    description: "Defines a security scheme for operations.",
    properties: %{
      type:
        JSV.Schema.string_to_atom_enum(
          %{
            description:
              "The type of the security scheme. Allowed values: apiKey, http, mutualTLS, oauth2, openIdConnect. Required."
          },
          [
            :apiKey,
            :http,
            :mutualTLS,
            :oauth2,
            :openIdConnect
          ]
        ),
      description: %{type: :string, description: "A description for the security scheme."},
      name: %{
        type: :string,
        description: "The name of the header, query, or cookie parameter (for apiKey). Required for apiKey."
      },
      in:
        JSV.Schema.string_to_atom_enum(
          %{
            description: "The location of the API key. Allowed values: query, header, cookie. Required for apiKey."
          },
          [
            :query,
            :header,
            :cookie
          ]
        ),
      scheme: %{
        type: :string,
        description: "The HTTP authentication scheme name. Required for http."
      },
      bearerFormat: %{
        type: :string,
        description: "The format of the bearer token (for http with 'bearer' scheme)."
      },
      flows: Moonwalk.Spec.OAuthFlows,
      openIdConnectUrl: %{
        type: :string,
        description: "The URL to discover OpenID Connect configuration. Required for openIdConnect."
      }
    },
    required: [:type]
  })
end
