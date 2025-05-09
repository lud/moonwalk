defmodule Moonwalk.Spec.Responses do
  require JSV
  use Moonwalk.Spec

  def schema do
    JSV.Schema.normalize(%{
      title: "Responses",
      type: :object,
      properties: %{
        default: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]}
      },
      additionalProperties: %{oneOf: [Moonwalk.Spec.Response, Moonwalk.Spec.Reference]}
    })
  end
end
