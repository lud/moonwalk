defmodule Moonwalk.ConnCase do
  alias Moonwalk.TestWeb.Responder
  import ExUnit.Assertions
  require Phoenix.ConnTest
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint Moonwalk.TestWeb.Endpoint

      import unquote(__MODULE__)
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.Controller, only: [json: 2, text: 2, html: 2]

      use Moonwalk.TestWeb, :verified_routes
    end
  end

  setup _tags do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end

  def with_response(conn, fun) when is_function(fun, 2) do
    Responder.embed_responder(conn, fun)
  end

  def check_responder(conn) do
    %{private: %{phoenix_controller: controller, phoenix_action: action}} = conn

    assert conn.private.responder_called,
           "#{inspect(controller)}.#{action} did not call the responder"

    conn
  end
end
