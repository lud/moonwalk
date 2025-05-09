defmodule Moonwalk.Spec.Callback do
  require JSV
  use Moonwalk.Spec

  def schema do
    JSV.Schema.normalize(%{
      title: "Callback",
      type: :object,
      additionalProperties: Moonwalk.Spec.PathItem
    })
  end
end
