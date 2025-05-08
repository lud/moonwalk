defmodule Moonwalk.ConnCase do
  alias Moonwalk.TestWeb.Responder
  import ExUnit.Assertions
  require Phoenix.ConnTest
  use ExUnit.CaseTemplate

  @endpoint Moonwalk.TestWeb.Endpoint

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

  setup tags do
    req_content_type = Map.get(tags, :req_content_type, "application/json")
    req_accept = Map.get(tags, :req_accept, "application/json")

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("content-type", req_content_type)
      |> Plug.Conn.put_req_header("accept", req_accept)

    {:ok, conn: conn}
  end

  def with_response(conn, fun) when is_function(fun, 2) do
    Responder.embed_responder(conn, fun)
  end

  def check_responder(conn) do
    case conn do
      %{state: :unset} ->
        flunk("response was not sent")

      %{private: %{responder_called: true}} ->
        conn

      %{
        private: %{
          responder_called: false,
          phoenix_controller: controller,
          phoenix_action: action
        },
        resp_body: resp_body
      } ->
        flunk("""
        #{inspect(controller)}.#{action} did not call the responder

        RESPONSE BODY
        #{resp_body}
        """)
    end
  end

  def post_reply(conn, path, payload, fun) when is_function(fun, 2) do
    conn
    |> with_response(fun)
    |> Phoenix.ConnTest.post(path, payload)
    |> check_responder()
  end
end
