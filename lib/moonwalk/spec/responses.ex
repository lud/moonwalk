defmodule Moonwalk.Spec.Responses do
  require JSV
  use Moonwalk.Internal.Normalizer

  IO.warn("TODO enable minProperties: 1")

  # Container for expected responses of an operation.
  def schema do
    JSV.Schema.normalize(%JSV.Schema{
      title: "Responses",
      type: :object,
      description: "Container for expected responses of an operation.",
      properties: %{
        default: %{
          oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference],
          description:
            "Documentation of responses other than ones declared for specific HTTP response codes."
        }
      },
      # minProperties: 1,
      additionalProperties: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]}
    })
  end

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_subs(default: {:or_ref, Moonwalk.Spec.Response})
    |> normalize_subs(fn
      _key, %{"$ref" => ref}, ctx -> {%{"$ref" => ref}, ctx}
      _key, %{"$ref": ref}, ctx -> {%{"$ref" => ref}, ctx}
      _key, value, ctx -> {_, _} = normalize!(value, Moonwalk.Spec.Response, ctx)
    end)
    |> collect()
  end
end
