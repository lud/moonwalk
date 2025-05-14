defmodule Moonwalk.Web.ParamTest do
  use Moonwalk.ConnCase, async: true

  # Testing using the following routes.
  #
  # /params/t/:theme
  # /params/t/:theme/c/:color
  # /params/s/:shape
  # /params/s/:shape/t/:theme
  # /params/s/:shape/t/:theme/c/:color
  #
  # - /s/:shape accepts only "square" or "circle"
  # - /t/:theme accepts only "dark" or "light"
  # - /c/:color accepts only "red" or "blue"

  describe "single path param" do
    test "valid param", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/params/t/dark", fn conn, _params ->
          assert %{theme: :dark} = conn.private.moonwalk.path_params
          json(conn, %{data: "shadows!"})
        end)

      assert %{"data" => "shadows!"} = json_response(conn, 200)
    end

    test "invalid param", %{conn: conn} do
      conn = get(conn, ~p"/params/t/UNKNOWN_THEME")

      assert %{
               "error" => %{
                 "message" => "Unprocessable Entity",
                 "path_parameters" => %{
                   "theme" => %{
                     "details" => [_],
                     "valid" => false
                   }
                 }
               }
             } = json_response(conn, 422)
    end

    # plain text is rendered for everything else than json
    @tag req_accept: "text/html"
    test "invalid param text errors", %{conn: conn} do
      conn = get(conn, ~p"/params/t/UNKNOWN_THEME")

      assert """
             <h1>Unprocessable Entity</h1>

             <p>Invalid parameter <code>theme</code> in <code>path</code>:</p>

             <pre>
             json schema validation failed

             at: "#"
             by: "#"
             errors:
               - (enum) value must be one of the enum values: "dark" or "light"
             <pre>

             """ = response(conn, 422)
    end
  end
end
