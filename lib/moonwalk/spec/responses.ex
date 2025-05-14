defmodule Moonwalk.Spec.Responses do
  require JSV
  use Moonwalk.Spec

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
      minProperties: 1,
      additionalProperties: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]}
    })
  end
end
