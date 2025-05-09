defmodule Moonwalk.Spec.Paths do
  require JSV
  use Moonwalk.Spec

  def schema do
    JSV.Schema.normalize(%{
      title: "Paths",
      type: :object,
      additionalProperties: Moonwalk.Spec.PathItem
    })
  end
end
