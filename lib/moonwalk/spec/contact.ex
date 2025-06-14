defmodule Moonwalk.Spec.Contact do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Contact information for the exposed API.
  JSV.defschema(%{
    title: "Contact",
    type: :object,
    description: "Contact information for the exposed API.",
    properties: %{
      name: %{
        type: :string,
        description: "The identifying name of the contact person or organization."
      },
      url: %{type: :string, description: "A URI for the contact information."},
      email: %{
        type: :string,
        description: "The email address of the contact person or organization."
      }
    },
    required: []
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_subs(openapi: :default, info: Moonwalk.Spec.Info, paths: Moonwalk.Spec.Paths)
    |> normalize_default(:all)
    |> collect()
  end
end
