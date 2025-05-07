defmodule Moonwalk.TestWeb.BodyController do
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  def with_inline_schema(conn, params) do
    Responder.reply(conn, params)
  end
end
