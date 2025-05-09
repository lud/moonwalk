defmodule Moonwalk.Spec.Responses do
  import JSV
  use Moonwalk.Spec

  def schema,do: (%{
    title: "Responses",
    type: :object,
    properties: %{
      default: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]}
    },
    additionalProperties: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]}
  })
end
