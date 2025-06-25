defmodule Moonwalk.TestWeb do
  def controller do
    quote do
      use Moonwalk.Controller
      import Plug.Conn

      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: []

      import Moonwalk.TestWeb.Helpers

      plug Moonwalk.Plugs.ValidateRequest

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Moonwalk.TestWeb.Endpoint,
        router: Moonwalk.TestWeb.Router
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule Moonwalk.TestWeb.Helpers do
  def dummy_responses do
    [ok: {%{_dummy_schema: true}, []}]
  end
end
