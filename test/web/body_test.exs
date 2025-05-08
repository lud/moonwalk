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

  describe "POST /body/inline-single" do
    test "inline schema valid body", %{conn: conn} do
      conn =
        post_reply(conn, ~p"/body/inline-single", @valid_payload, fn conn, _params ->
          json(conn, %{data: "alright!"})
        end)

      assert %{"data" => "alright!"} = json_response(conn, 200)
    end

    test "inline schema invalid body", %{conn: conn} do
      conn = post(conn, ~p"/body/inline-single", @invalid_payload)

      assert %{"error" => %{"detail" => %{"valid" => false}}} = json_response(conn, 422)
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
      assert "Unsupported Media Type" = response(conn, 415)
    end

    @tag req_content_type: "application/x-www-form-urlencoded"
    test "invalid content type returns 415 Unsupported Media Type in JSON format", %{conn: conn} do
      conn = post(conn, ~p"/body/inline-single", URI.encode_query(a: 1, b: 2))
      assert %{"error" => %{"message" => "Unsupported Media Type"}} = json_response(conn, 415)
    end
  end

  describe "POST /body/module-single" do
    # Same test as before but the schema is given as a module
    test "module schema valid body", %{conn: conn} do
      conn =
        post_reply(conn, ~p"/body/module-single", @valid_payload, fn conn, _params ->
          # the controller using a defschema module, so we should have a struct here
          assert %Moonwalk.TestWeb.BodyController.PlantSchema{
                   name: "Monstera Deliciosa",
                   sunlight: :bright_indirect
                 } = conn.private.moonwalk.body_params

          json(conn, %{data: "alright!"})
        end)

      assert %{"data" => "alright!"} = json_response(conn, 200)
    end

    test "module schema invalid body", %{conn: conn} do
      conn = post(conn, ~p"/body/module-single", @invalid_payload)

      assert %{"error" => %{"detail" => %{"valid" => false}}} = json_response(conn, 422)
    end
  end

  describe "POST /body/form" do
    @describetag req_content_type: "application/x-www-form-urlencoded", req_accept: "text/html"
    test "form submission valid body", %{conn: conn} do
      form_data = URI.encode_query(@valid_payload)

      conn =
        post_reply(conn, ~p"/body/form", form_data, fn conn, _params ->
          text(conn, "okay!")
        end)

      assert "okay!" = response(conn, 200)
    end

    test "form submission invalid body", %{conn: conn} do
      conn = post(conn, ~p"/body/form", @invalid_payload)

      assert errmsg = response(conn, 422)
      assert is_binary(errmsg)
    end
  end

  describe "POST /body/undefined-operation" do
    # When an operation is not defined but the plug is called, it will log a
    # warning.
    test "nothing is validated and nothing is logged", %{conn: conn} do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          payload = ~s({"some":"stuff"})

          conn =
            post_reply(conn, ~p"/body/undefined-operation", payload, fn conn, _params ->
              text(conn, "anyway")
            end)

          assert "anyway" == response(conn, 200)
        end)

      assert log =~
               "Controller Moonwalk.TestWeb.BodyController has no operation defined for action :undefined_operation"
    end
  end

  describe "POST /body/ignored-action" do
    test "no logs are output if an action has an explicit false operation", %{conn: conn} do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          payload = ~s({"some":"stuff"})

          conn =
            post_reply(conn, ~p"/body/ignored-action", payload, fn conn, _params ->
              text(conn, "anyway")
            end)

          assert "anyway" == response(conn, 200)
        end)

      refute log =~ "BodyController"
    end
  end
end
