defmodule Moonwalk.Spec.Callback do
  import JSV
  use Moonwalk.Spec

  def schema do
    %{
      title: "Callback",
      type: :object,
      additionalProperties: Moonwalk.Spec.PathItem
    }
  end
end
