defmodule Moonwalk.Spec.MediaType do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "MediaType",
    type: :object,
    description: "Provides schema and examples for a media type.",
    properties: %{
      schema: Moonwalk.Spec.SchemaWrapper,
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
        description: "Examples"
      }
      # encoding: %{
      #   type: :object,
      #   additionalProperties: Moonwalk.Spec.Encoding,
      #   description: "Encoding"
      # }
    },
    required: []
  })

  def from_controller!(spec) do
    default_examples =
      case Access.fetch(spec, :example) do
        {:ok, example} -> [example]
        :error -> []
      end

    spec
    |> make(__MODULE__)
    |> take_required(:schema)
    |> take_default(:examples, default_examples)
    |> into()
  end
end
