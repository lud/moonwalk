defmodule Moonwalk.TestWeb do
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: []

      # plug :put_view, [json: {PhxAppWeb.LayoutView, :guest}]

      import Plug.Conn

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
