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
                 "operation_id" => "param_single_path_param",
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

      body = response(conn, 422)
      assert body =~ ~r{<!doctype html>.+Unprocessable Entity}s
      assert body =~ ~r{<p>Invalid parameter <code>theme</code> in <code>path</code>\.</p>}s
      assert body =~ "<p>Invalid parameter <code>theme</code> in <code>path</code>.</p>"
      assert body =~ ~S(value must be one of the enum values: "dark" or "light")
    end
  end

  describe "two path params (no scope)" do
    test "two invalid path params", %{conn: conn} do
      conn = get(conn, ~p"/params/t/UNKNOWN_THEME/c/UNKNOWN_COLOR")

      assert %{
               "error" => %{
                 "operation_id" => "param_two_path_params",
                 "message" => "Unprocessable Entity",
                 "path_parameters" => %{
                   "theme" => %{
                     "details" => [_],
                     "valid" => false
                   },
                   "color" => %{
                     "details" => [_],
                     "valid" => false
                   }
                 }
               }
             } = json_response(conn, 422)
    end

    test "one valid, one invalid path param", %{conn: conn} do
      conn = get(conn, ~p"/params/t/dark/c/UNKNOWN_COLOR")

      assert %{
               "error" => %{
                 "operation_id" => "param_two_path_params",
                 "message" => "Unprocessable Entity",
                 "path_parameters" => %{
                   "color" => %{
                     "details" => [_],
                     "valid" => false
                   }
                 }
               }
             } = json_response(conn, 422)
    end

    test "both valid path params", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/params/t/dark/c/red", fn conn, _params ->
          assert %{theme: :dark, color: :red} = conn.private.moonwalk.path_params
          json(conn, %{data: "dark red theme applied"})
        end)

      assert %{"data" => "dark red theme applied"} = json_response(conn, 200)
    end
  end

  describe "scope and path params" do
    test "valid scope param, invalid path param", %{conn: conn} do
      conn = get(conn, ~p"/params/s/circle/t/UNKNOWN_THEME")

      assert %{
               "error" => %{
                 "operation_id" => "param_scope_and_single",
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

    test "invalid scope param, valid path param", %{conn: conn} do
      conn = get(conn, ~p"/params/s/UNKNOWN_SHAPE/t/dark")

      assert %{
               "error" => %{
                 "operation_id" => "param_scope_and_single",
                 "message" => "Unprocessable Entity",
                 "path_parameters" => %{
                   "shape" => %{
                     "details" => [_],
                     "valid" => false
                   }
                 }
               }
             } = json_response(conn, 422)
    end

    test "both scope and path params invalid", %{conn: conn} do
      conn = get(conn, ~p"/params/s/UNKNOWN_SHAPE/t/UNKNOWN_THEME")

      assert %{
               "error" => %{
                 "operation_id" => "param_scope_and_single",
                 "message" => "Unprocessable Entity",
                 "path_parameters" => %{
                   "shape" => %{
                     "details" => [_],
                     "valid" => false
                   },
                   "theme" => %{
                     "details" => [_],
                     "valid" => false
                   }
                 }
               }
             } = json_response(conn, 422)
    end

    test "both scope and path params valid", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/params/s/square/t/light", fn conn, _params ->
          assert %{shape: :square, theme: :light} = conn.private.moonwalk.path_params
          json(conn, %{data: "square with light theme"})
        end)

      assert %{"data" => "square with light theme"} = json_response(conn, 200)
    end
  end
end
