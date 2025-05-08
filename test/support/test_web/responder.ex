defmodule Moonwalk.TestWeb.Responder do
  def embed_responder(conn, fun) do
    conn
    |> Plug.Conn.put_private(:responder_fun, fun)
    |> Plug.Conn.put_private(:responder_called, false)
  end

  def reply(conn, params) do
    case conn.private do
      %{responder_fun: fun} ->
        conn = Plug.Conn.put_private(conn, :responder_called, true)

        fun.(conn, params)

      _ ->
        ExUnit.Assertions.flunk("""
        Responder was not set
        """)
    end
  end
end
