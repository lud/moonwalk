defmodule Moonwalk.TestWeb.PathsApiSpec do
  alias Moonwalk.Spec.Paths
  alias Moonwalk.Spec.Server
  use Moonwalk

  @impl true
  def spec do
    %{
      openapi: "3.1.1",
      info: %{title: "Moonwalk Test API", version: "0.0.0"},
      paths:
        Paths.from_router(Moonwalk.TestWeb.Router,
          filter: fn route ->
            case route.path do
              "/generated" <> _ -> true
              _ -> false
            end
          end
        ),
      servers: [Server.from_config(:moonwalk, Moonwalk.TestWeb.Endpoint)]
    }
  end
end
