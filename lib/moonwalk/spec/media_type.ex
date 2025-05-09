defmodule Moonwalk.Spec.MediaType do
  require JSV
  use Moonwalk.Spec

  JSV.defschema(%{
    title: "MediaType",
    type: :object,
    properties: %{
      schema: Moonwalk.Spec.SchemaWrapper,
      example: %{description: "Example"},
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
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

  IO.warn("remove build schema from there")

  @always_schema JSV.build!(true)
  @never_schema JSV.build!(false)

  def from_controller!(spec, opts) do
    default_examples =
      case Access.fetch(spec, :example) do
        {:ok, example} -> [example]
        :error -> []
      end

    spec
    |> make(__MODULE__)
    |> take_required(:schema, &build_schema(&1, opts))
    |> take_default(:examples, default_examples)
    |> into()
  end

  defp build_schema(true, _opts) do
    {:ok, @always_schema}
  end

  defp build_schema(false, _opts) do
    {:ok, @never_schema}
  end

  defp build_schema(schema, _opts) do
    JSV.build(schema)
  end
end
