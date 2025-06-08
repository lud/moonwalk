defmodule Moonwalk.Web.BodyTest do
  use Moonwalk.ConnCase, async: true

  @valid_payload %{
    "name" => "Monstera Deliciosa",
    "sunlight" => "bright_indirect"
  }

  @invalid_payload %{
    "name" => "Bird of Paradise",
    "sunlight" => "SOME INVALID SUNLIGHT"
  }

  @invalid_sub %{
    "name" => "Bird of Paradise",
    "sunlight" => "bright_indirect",
    "soil" => %{"acid" => true, "density" => "NOT A NUMBER"}
  }

  describe "inline schema" do
    test "valid body", %{conn: conn} do
      conn =
        post_reply(conn, ~p"/body/inline-single", @valid_payload, fn conn, _params ->
          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end

    test "invalid body", %{conn: conn} do
      conn = post(conn, ~p"/body/inline-single", @invalid_payload)

      assert %{
               "error" => %{
                 "message" => "Unprocessable Entity",
                 "operation_id" => "body_inline_single" <> _,
                 "errors" => [
                   %{
                     "in" => "body",
                     "kind" => "invalid_body",
                     "message" => "invalid body",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    @tag req_accept: "text/html"
    test "can return textual errors", %{conn: conn} do
      conn = post(conn, ~p"/body/inline-single", @invalid_payload)

      assert errmsg = response(conn, 422)
      assert is_binary(errmsg)
    end

    @tag req_content_type: "application/x-www-form-urlencoded", req_accept: "text/html"
    test "invalid content type returns 415 Unsupported Media Type", %{conn: conn} do
      conn = post(conn, ~p"/body/inline-single", URI.encode_query(a: 1, b: 2))

      assert response(conn, 415) =~ ~r{<!doctype html>.+Unsupported Media Type}s
    end

    @tag req_content_type: "application/x-www-form-urlencoded"
    test "invalid content type returns 415 Unsupported Media Type in JSON format", %{conn: conn} do
      conn = post(conn, ~p"/body/inline-single", URI.encode_query(a: 1, b: 2))

      assert %{
               "error" => %{
                 "message" => "Unsupported Media Type",
                 "media_type" => "application/x-www-form-urlencoded"
               }
             } =
               json_response(conn, 415)
    end

    test "body is required but not provided" do
      IO.warn("todo :required option in RequestBody")
    end
  end

  describe "module-based schema" do
    # Same test as before but the schema is given as a module
    test "valid body", %{conn: conn} do
      conn =
        post_reply(conn, ~p"/body/module-single", @valid_payload, fn conn, _params ->
          # the controller using a defschema module, so we should have a struct here
          assert %Moonwalk.TestWeb.BodyController.PlantSchema{
                   name: "Monstera Deliciosa",
                   sunlight: :bright_indirect
                 } = conn.private.moonwalk.body_params

          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end

    test "invalid body", %{conn: conn} do
      conn = post(conn, ~p"/body/module-single", @invalid_payload)

      assert %{
               "error" => %{
                 "message" => "Unprocessable Entity",
                 "operation_id" => "custom_operation_id_module_single",
                 "errors" => [
                   %{
                     "in" => "body",
                     "kind" => "invalid_body",
                     "message" => "invalid body",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    test "invalid body in sub schema", %{conn: conn} do
      conn = post(conn, ~p"/body/module-single", @invalid_sub)

      # schema locations should be in #/components/schemas/...
      assert %{
               "error" => %{
                 "message" => "Unprocessable Entity",
                 "operation_id" => "custom_operation_id_module_single",
                 "errors" => [
                   %{
                     "in" => "body",
                     "kind" => "invalid_body",
                     "message" => "invalid body",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 422)
    end
  end

  describe "form data" do
    @describetag req_content_type: "application/x-www-form-urlencoded", req_accept: "text/html"
    test "valid body", %{conn: conn} do
      form_data = URI.encode_query(@valid_payload)

      conn =
        post_reply(conn, ~p"/body/form", form_data, fn conn, _params ->
          text(conn, "ok")
        end)

      assert "ok" = response(conn, 200)
    end

    test "invalid body", %{conn: conn} do
      conn = post(conn, ~p"/body/form", @invalid_payload)

      assert errmsg = response(conn, 422)
      assert is_binary(errmsg)
    end
  end

  describe "undefined operation" do
    # When an operation is not defined but the plug is called, it will log a
    # warning.
    test "nothing is validated and nothing is logged", %{conn: conn} do
      io =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          payload = ~s({"some":"stuff"})

          conn =
            post_reply(conn, ~p"/body/undefined-operation", payload, fn conn, _params ->
              text(conn, "ok")
            end)

          assert "ok" == response(conn, 200)
        end)

      assert io =~
               "Controller Moonwalk.TestWeb.BodyController has no operation defined for action :undefined_operation"
    end
  end

  describe "ignored action" do
    test "no logs are output if an action has an explicit false operation", %{conn: conn} do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          payload = ~s({"some":"stuff"})

          conn =
            post_reply(conn, ~p"/body/ignored-action", payload, fn conn, _params ->
              text(conn, "ok")
            end)

          assert "ok" == response(conn, 200)
        end)

      refute log =~ "BodyController"
    end
  end

  describe "wildcard content types" do
    @tag req_content_type: "some-unknown-content-type"
    test "wildcard take any content type", %{conn: conn} do
      # schema with wildcard content type is just `false`
      conn = post(conn, ~p"/body/wildcard", "some payload")

      assert %{
               "error" => %{
                 "message" => "Unprocessable Entity",
                 "operation_id" => "body_wildcard_media_type" <> _,
                 "errors" => [
                   %{
                     "in" => "body",
                     "kind" => "invalid_body",
                     "message" => "invalid body",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    test "wildcard does not take priority over more specific content types", %{conn: conn} do
      # the route exposes the regular PlantSchema for application/json
      conn =
        post_reply(conn, ~p"/body/wildcard", @valid_payload, fn conn, _params ->
          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end
  end
end
