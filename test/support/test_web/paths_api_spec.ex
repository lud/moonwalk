defmodule Moonwalk.TestWeb.PathsApiSpec do
  alias Moonwalk.Spec.Paths
  use Moonwalk.Spec

  def spec do
    %{
      :openapi => "3.1.1",
      :info => %{"title" => "Moonwalk Test API", :version => "0.0.0"},
      :paths => Paths.from_router(Moonwalk.TestWeb.Router)
    }
  end
end
