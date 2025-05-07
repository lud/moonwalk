defmodule Moonwalk.Web.MetaTest do
  use Moonwalk.ConnCase, async: true

  test "GET /meta/hello returns hello world", %{conn: conn} do
    conn = get(conn, ~p"/meta/hello")
    assert response(conn, 200) == "hello world"
  end
end
