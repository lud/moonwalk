defmodule Moonwalk.Spec.Responses do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Container for expected responses of an operation.
  def schema do
    %JSV.Schema{
      title: "Responses",
      type: :object,
      description: "Container for expected responses of an operation.",
      properties: %{
        default: %{
          anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Response],
          description:
            "Documentation of responses other than ones declared for specific HTTP response codes."
        }
      },
      minProperties: 1,
      additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Response]}
    }
  end

  @impl true
  def normalize!(data, ctx) do
    data
    |> from(__MODULE__, ctx)
    |> normalize_subs(default: {:or_ref, Moonwalk.Spec.Response})
    |> normalize_subs(
      {:or_ref,
       fn
         value, ctx -> {_, _} = normalize!(value, Moonwalk.Spec.Response, ctx)
       end}
    )
    |> collect()
  end
end
