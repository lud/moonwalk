defmodule Moonwalk.Spec.Server do
  require JSV
  use Moonwalk.Internal.Normalizer

  # An object representing a server for the API.
  JSV.defschema(%{
    title: "Server",
    type: :object,
    description: "An object representing a server.",
    properties: %{
      url: %{
        type: :string,
        description: "The URL to the target host. Required. Supports server variables."
      },
      description: %{
        type: :string,
        description: "An optional string describing the host designated by the URL."
      },
      variables: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.ServerVariable,
        description: "A map between variable names and their values for substitution in the server's URL template."
      }
    },
    required: [:url]
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default([:url, :description])
    |> normalize_subs(variables: {:map, Moonwalk.Spec.ServerVariable})
    |> collect()
  end
end
