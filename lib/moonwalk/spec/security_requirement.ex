defmodule Moonwalk.Spec.SecurityRequirement do
  require JSV
  use Moonwalk.Spec

  # Lists required security schemes to execute an operation.
  def schema do
    JSV.Schema.normalize(%{
      title: "SecurityRequirement",
      type: :object,
      description:
        "Lists required security schemes to execute an operation, mapping each scheme name to a list of scopes or roles.",
      additionalProperties: %{type: :array, items: %{type: :string}}
    })
  end
end
