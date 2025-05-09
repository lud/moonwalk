defmodule Moonwalk.Spec.SecurityRequirement do
  require JSV
  use Moonwalk.Spec

  def schema do
    JSV.Schema.normalize(%{
      title: "SecurityRequirement",
      type: :object,
      additionalProperties: %{type: :array, items: %{type: :string}}
    })
  end
end
