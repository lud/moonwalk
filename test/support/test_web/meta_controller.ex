defmodule Moonwalk.TestWeb.MetaController do
  use Moonwalk.TestWeb, :controller

  # This controller is used to verify that we can start and test a phoenix
  # endpoint in tests.

  def hello(conn, _params) do
    text(conn, "hello world")
  end
end
