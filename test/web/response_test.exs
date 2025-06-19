defmodule Moonwalk.Web.ResponseTest do
  alias Moonwalk.TestWeb.PathsApiSpec
  use Moonwalk.ConnCase, async: true

  import Moonwalk.Test

  describe "with generated api" do
    test "responses can be validated", %{conn: conn} do
      conn = get(conn, ~p"/generated/resp/fortune-200-valid")
      assert %{"message" => _, "category" => _} = valid_response(PathsApiSpec, conn, 200) |> dbg()
    end

    test "expecting another status", %{conn: conn} do
      # here we just delegate to Phoenix.Conntest
      conn = get(conn, ~p"/generated/resp/fortune-200-valid")

      assert_raise RuntimeError, ~r{expected response with status 201, got: 200}, fn ->
        valid_response(PathsApiSpec, conn, 201) |> dbg()
      end
    end

    # New route that does not return data validated by the response schema
    test "response can be invalidated"

    # new route that does not declare conent in the response.
    test "response without defined response bodies"

    # New route with response returned as text/plain but the operation only application/json
    test "response with other content type"
  end
end
