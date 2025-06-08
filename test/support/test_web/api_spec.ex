defmodule Moonwalk.TestWeb.ApiSpec do
  alias Moonwalk.Spec.Paths
  use Moonwalk

  def spec do
    %{
      :openapi => "3.1.1",
      :info => %{"title" => "Moonwalk Test API", :version => "0.0.0"},
      :paths => Paths.from_router(Moonwalk.TestWeb.Router)
    }
  end
end
