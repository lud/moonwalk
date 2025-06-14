defmodule Moonwalk.Spec.Callback do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Map of possible out-of-band callbacks related to the parent operation.
  def schema do
    %{
      title: "Callback",
      type: :object,
      description:
        "Map of possible out-of-band callbacks related to the parent operation, mapping expressions to Path Item Objects.",
      additionalProperties: Moonwalk.Spec.PathItem
    }
  end
end
