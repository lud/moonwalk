defmodule Moonwalk.Spec.Callback do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Map of possible out-of-band callbacks related to the parent operation.
  def schema do
    JSV.Schema.normalize(%{
      title: "Callback",
      type: :object,
      description:
        "Map of possible out-of-band callbacks related to the parent operation, mapping expressions to Path Item Objects.",
      additionalProperties: Moonwalk.Spec.PathItem
    })
  end
end
