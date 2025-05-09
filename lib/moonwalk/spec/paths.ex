defmodule Moonwalk.Spec.Paths do
  require JSV
  use Moonwalk.Spec

  # Holds the relative paths to individual endpoints and their operations.
  def schema do
    JSV.Schema.normalize(%{
      title: "Paths",
      type: :object,
      description:
        "Holds the relative paths to individual endpoints and their operations, mapping each path to a Path Item Object.",
      additionalProperties: Moonwalk.Spec.PathItem
    })
  end
end
