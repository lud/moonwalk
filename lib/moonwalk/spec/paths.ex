defmodule Moonwalk.Spec.Paths do
  import JSV
  use Moonwalk.Spec

  def schema do
    %{
      title: "Paths",
      type: :object,
      additionalProperties: Moonwalk.Spec.PathItem
    }
  end
end
