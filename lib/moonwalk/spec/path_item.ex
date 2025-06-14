defmodule Moonwalk.Spec.PathItem do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Describes operations available on a single path.
  JSV.defschema(%{
    title: "PathItem",
    type: :object,
    description: "Describes operations available on a single path.",
    properties: %{
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

  defimpl Enumerable do
    @op_keys [:get, :put, :post, :delete, :options, :head, :patch, :trace]

    def reduce(path_item, arg, fun) do
      # Take with ordering to avoid schema reference naming randomness
      by_verb =
        Enum.flat_map([:get, :put, :post, :delete, :options, :head, :patch, :trace], fn k ->
          case Map.fetch!(path_item, k) do
            nil -> []
            v -> [{k, v}]
          end
        end)

      Enumerable.List.reduce(by_verb, arg, fun)
    end

    def member?(path_item, {k, v}) do
      case path_item do
        %{^k => ^v} -> {:ok, true}
        _ -> {:ok, false}
      end
    end

    def count(path_item) do
      {:ok, Enum.count(@op_keys, &(Map.fetch!(path_item, &1) != nil))}
    end

    def slice(_) do
      {:error, __MODULE__}
    end
  end
end
