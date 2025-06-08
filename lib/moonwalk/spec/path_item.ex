defmodule Moonwalk.Spec.PathItem do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Describes operations available on a single path.
  JSV.defschema(%{
    title: "PathItem",
    type: :object,
    description: "Describes operations available on a single path.",
    properties: %{
      "$ref": %{
        type: :string,
        description: "Allows for a referenced definition of this path item."
      },
      summary: %{
        type: :string,
        description: "An optional string summary for all operations in this path."
      },
      description: %{
        type: :string,
        description: "An optional string description for all operations in this path."
      },
      get: Moonwalk.Spec.Operation,
      put: Moonwalk.Spec.Operation,
      post: Moonwalk.Spec.Operation,
      delete: Moonwalk.Spec.Operation,
      options: Moonwalk.Spec.Operation,
      head: Moonwalk.Spec.Operation,
      patch: Moonwalk.Spec.Operation,
      trace: Moonwalk.Spec.Operation,
      servers: %{
        type: :array,
        items: Moonwalk.Spec.Server,
        description: "Alternative servers array for all operations in this path."
      },
      parameters: %{
        type: :array,
        items: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Parameter]},
        description: "Parameters applicable for all operations under this path."
      }
    },
    required: []
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_subs(
      get: Moonwalk.Spec.Operation,
      put: Moonwalk.Spec.Operation,
      post: Moonwalk.Spec.Operation,
      delete: Moonwalk.Spec.Operation,
      options: Moonwalk.Spec.Operation,
      head: Moonwalk.Spec.Operation,
      patch: Moonwalk.Spec.Operation,
      trace: Moonwalk.Spec.Operation,
      servers: {:list, Moonwalk.Spec.Server},
      parameters: {:list, {:or_ref, Moonwalk.Spec.Parameter}}
    )
    |> collect()
  end
end
