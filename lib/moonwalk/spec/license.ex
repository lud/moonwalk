defmodule Moonwalk.Spec.License do
  require JSV
  use Moonwalk.Internal.Normalizer

  # License information for the exposed API.
  JSV.defschema(%{
    title: "License",
    type: :object,
    description: "License information for the exposed API.",
    properties: %{
      name: %{type: :string, description: "The name of the license used for the API. Required."},
      identifier: %{
        type: :string,
        description: "An SPDX expression for the API license. Mutually exclusive with url."
      },
      url: %{
        type: :string,
        description: "A URI for the license used for the API. Mutually exclusive with identifier."
      }
    },
    required: [:name]
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default(:all)
    |> collect()
  end
end
