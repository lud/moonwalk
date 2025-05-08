defmodule Moonwalk.Spec.Info do
  import Moonwalk.Spec

  @enforce_keys [:title, :version]
  defstruct [:title, :summary, :description, :version]

  def build!(spec) do
    spec
    |> make(__MODULE__)
    |> take_required(:openapi)
    |> take_required(:info)
    |> into()
  end
end
