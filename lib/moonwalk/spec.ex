defmodule Moonwalk.Spec do
  alias Moonwalk.Internal.Normalizer

  IO.warn("move this function to Moonwalk facade")

  def normalize!(data) do
    Normalizer.normalize!(data)
  end
end
