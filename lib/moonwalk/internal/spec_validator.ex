defmodule Moonwalk.Internal.SpecValidator do
  alias Moonwalk.Spec.OpenAPI
  require Moonwalk.Internal.Normalizer
  require Moonwalk.Spec.Callback
  require Moonwalk.Spec.Components
  require Moonwalk.Spec.Contact
  require Moonwalk.Spec.Discriminator
  require Moonwalk.Spec.Encoding
  require Moonwalk.Spec.Example
  require Moonwalk.Spec.ExternalDocumentation
  require Moonwalk.Spec.Header
  require Moonwalk.Spec.Info
  require Moonwalk.Spec.License
  require Moonwalk.Spec.Link
  require Moonwalk.Spec.MediaType
  require Moonwalk.Spec.OAuthFlow
  require Moonwalk.Spec.OAuthFlows
  require Moonwalk.Spec.OpenAPI
  require Moonwalk.Spec.Operation
  require Moonwalk.Spec.Parameter
  require Moonwalk.Spec.PathItem
  require Moonwalk.Spec.Paths
  require Moonwalk.Spec.Reference
  require Moonwalk.Spec.RequestBody
  require Moonwalk.Spec.Response
  require Moonwalk.Spec.Responses
  require Moonwalk.Spec.SchemaWrapper
  require Moonwalk.Spec.SecurityRequirement
  require Moonwalk.Spec.SecurityScheme
  require Moonwalk.Spec.Server
  require Moonwalk.Spec.ServerVariable
  require Moonwalk.Spec.Tag
  require Moonwalk.Spec.XML

  @openapi_schema JSV.build!(OpenAPI)

  def validate!(data) do
    JSV.validate!(data, @openapi_schema)
  end

  def validate(data) do
    JSV.validate(data, @openapi_schema)
  end
end
