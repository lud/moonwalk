defmodule Moonwalk.Spec.MediaType do
  alias Moonwalk.Spec.Reference
  import Moonwalk.Internal.ControllerBuilder
  require JSV
  use Moonwalk.Internal.SpecObject

  JSV.defschema(%{
    title: "MediaType",
    type: :object,
    description: "Provides schema and examples for a media type.",
    properties: %{
      schema: Moonwalk.Spec.SchemaWrapper,
      examples: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Example]},
        description: "Examples"
      },
      encoding: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.Encoding,
        description: "Encoding"
      }
    },
    required: []
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> from(__MODULE__, ctx)
    |> normalize_default([:tags, :summary, :description, :operationId, :deprecated, :encoding])
    |> normalize_subs(
      examples: {:map, {:or_ref, :default}},
      encoding: {:map, Moonwalk.Spec.Encoding}
    )
    |> normalize_schema(:schema)
    |> collect()
  end

  def from_controller!(%Reference{} = ref) do
    ref
  end

  def from_controller!(spec) do
    spec
    |> build(__MODULE__)
    |> take_required(:schema)
    |> take_default_lazy(:examples, fn ->
      case Access.fetch(spec, :example) do
        {:ok, example} -> %{"default" => example}
        :error -> nil
      end
    end)
    |> into()
  end
end
