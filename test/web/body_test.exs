defmodule Moonwalk.Web.BodyTest do
  alias Moonwalk.TestWeb.BodyController
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.ConnCase, async: true

  test "validates body using inline schema", %{conn: conn} do
    conn =
      conn
      |> with_response(fn conn, params -> json(conn, %{data: "hello"}) end)
      |> post(~p"/body/post/inline", %{some: :payload})
      |> check_responder()

    assert %{"data" => "hello"} = json_response(conn, 200)
  end
end
