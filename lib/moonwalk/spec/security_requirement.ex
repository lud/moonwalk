defmodule Moonwalk.Spec.SecurityRequirement do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Lists required security schemes to execute an operation.
  def schema do
    %{
      title: "SecurityRequirement",
      type: :object,
      description:
        "Lists required security schemes to execute an operation, mapping each scheme name to a list of scopes or roles.",
      additionalProperties: %{type: :array, items: %{type: :string}}
    }
  end

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default(:all)
    |> collect()
  end
end
