defmodule Moonwalk.Spec.Info do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Provides metadata about the API, such as title, version, and contact information.
  JSV.defschema(%{
    title: "Info",
    type: :object,
    description: "Metadata about the API.",
    properties: %{
      title: %{type: :string, description: "The title of the API. Required."},
      summary: %{type: :string, description: "A short summary of the API's purpose."},
      description: %{type: :string, description: "A detailed description of the API."},
      termsOfService: %{type: :string, description: "A URI for the Terms of Service for the API."},
      contact: Moonwalk.Spec.Contact,
      license: Moonwalk.Spec.License,
      version: %{type: :string, description: "The version of the OpenAPI document. Required."}
    },
    required: [:title, :version]
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_subs(
      contact: Moonwalk.Spec.Contact,
      license: Moonwalk.Spec.License
    )
    |> normalize_default(:all)
    |> collect()
  end
end
