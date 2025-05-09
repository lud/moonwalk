defmodule Moonwalk.Spec.SecurityRequirement do
  import JSV
  use Moonwalk.Spec

  def schema do
    %{
      title: "SecurityRequirement",
      type: :object,
      additionalProperties: %{type: :array, items: %{type: :string}}
    }
  end
end
