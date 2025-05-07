defmodule Moonwalk.TestWeb.Responder do
  def embed_responder(conn, fun) do
    conn
    |> Plug.Conn.put_private(:responder_fun, fun)
    |> Plug.Conn.put_private(:responder_called, false)
  end

  def reply(conn, params) do
    fun = conn.private.responder_fun
    conn = Plug.Conn.put_private(conn, :responder_called, true)

    fun.(conn, params)
  end
end
