defmodule Moonwalk.Spec.MediaType do
  import Moonwalk.Internal.ControllerBuilder
  require JSV
  use Moonwalk.Internal.Normalizer

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

  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default([:tags, :summary, :description, :operationId, :deprecated])
    |> normalize_subs(
      examples: {:map, {:or_ref, :defaultxxx}},
      encoding: {:map, Moonwalk.Spec.Encoding}
    )
    |> normalize_schema(:schema)
    |> collect()
  end

  def from_controller!(spec) do
    default_examples =
      case Access.fetch(spec, :example) do
        {:ok, example} -> %{"default" => example}
        :error -> nil
      end

    spec
    |> build(__MODULE__)
    |> take_required(:schema)
    |> take_default(:examples, default_examples)
    |> into()
  end
end
