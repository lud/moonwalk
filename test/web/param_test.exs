defmodule Moonwalk.Web.ParamTest do
  use Moonwalk.ConnCase, async: true

  # Testing using the following routes.
  #
  # /params/some-slug/t/:theme
  # /params/some-slug/t/:theme/c/:color
  # /params/some-slug/s/:shape
  # /params/some-slug/s/:shape/t/:theme
  # /params/some-slug/s/:shape/t/:theme/c/:color
  #
  # - /s/:shape accepts only "square" or "circle"
  # - /t/:theme accepts only "dark" or "light"
  # - /c/:color accepts only "red" or "blue"

  describe "single path param" do
    test "valid param", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/generated/params/some-slug/t/dark", fn conn, _params ->
          assert %{theme: :dark} = conn.private.moonwalk.path_params
          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end

    test "invalid param", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/t/UNKNOWN_THEME")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_single_path_param" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter theme in path",
                     "parameter" => "theme",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end
  end

  describe "two path params (no scope)" do
    test "two invalid path params", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/BAD_SLUG/t/UNKNOWN_THEME/c/UNKNOWN_COLOR")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_two_path_params" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter color in path",
                     "parameter" => "color",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter slug in path",
                     "parameter" => "slug",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter theme in path",
                     "parameter" => "theme",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "one valid, one invalid path param", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/t/dark/c/UNKNOWN_COLOR")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_two_path_params" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter color in path",
                     "parameter" => "color",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "both valid path params", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/generated/params/some-slug/t/dark/c/red", fn conn, _params ->
          assert %{theme: :dark, color: :red} = conn.private.moonwalk.path_params
          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end
  end

  describe "scope and path params" do
    test "valid scope param, invalid path param", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/s/circle/t/UNKNOWN_THEME")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_scope_and_single" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter theme in path",
                     "parameter" => "theme",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "invalid scope param, valid path param", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/s/UNKNOWN_SHAPE/t/dark")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_scope_and_single" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter shape in path",
                     "parameter" => "shape",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "both scope and path params invalid", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/s/UNKNOWN_SHAPE/t/UNKNOWN_THEME")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_scope_and_single" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter shape in path",
                     "parameter" => "shape",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "path",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter theme in path",
                     "parameter" => "theme",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "both scope and path params valid", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/generated/params/some-slug/s/square/t/light", fn conn, _params ->
          assert %{shape: :square, theme: :light} = conn.private.moonwalk.path_params
          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end
  end

  # Query params on this route accept integers in 0..100
  describe "query params" do
    test "valid query params with integers", %{conn: conn} do
      conn =
        get_reply(
          conn,
          ~p"/generated/params/some-slug/s/square/t/light/c/red?shape=10&theme=20&color=30",
          fn
            conn, params ->
              # standard phoenix behaviour should not be changed, the path params have priority
              assert %{
                       "slug" => "some-slug",
                       "shape" => "square",
                       "theme" => "light",
                       "color" => "red"
                     } == params

              assert %{"shape" => "10", "theme" => "20", "color" => "30"} == conn.query_params

              # moonwalk data is properly cast
              assert %{slug: "some-slug", shape: :square, theme: :light, color: :red} ==
                       conn.private.moonwalk.path_params

              assert %{shape: 10, theme: 20, color: 30} == conn.private.moonwalk.query_params

              json(conn, %{data: "okay"})
          end
        )

      assert %{"data" => "okay"} = json_response(conn, 200)
    end

    test "invalid query params with too large integers", %{conn: conn} do
      # Ensures that our schemas for the query params are not overriden by the
      # schemas of the path params

      conn =
        get(
          conn,
          ~p"/generated/params/some-slug/s/square/t/light/c/red?shape=1010&theme=1020&color=1030"
        )

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_scope_and_two_path_params" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter color in query",
                     "parameter" => "color",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter shape in query",
                     "parameter" => "shape",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter theme in query",
                     "parameter" => "theme",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "invalid query params with same values as path", %{conn: conn} do
      # Ensures that our schemas for the query params are not overriden by the
      # schemas of the path params

      conn =
        get(
          conn,
          ~p"/generated/params/some-slug/s/square/t/light/c/red?shape=square&theme=light&color=red"
        )

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_scope_and_two_path_params" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter color in query",
                     "parameter" => "color",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter shape in query",
                     "parameter" => "shape",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter theme in query",
                     "parameter" => "theme",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "required query param is missing", %{conn: conn} do
      # The shape query param is required
      conn = get(conn, ~p"/generated/params/some-slug/s/square/t/light/c/red?theme=20&color=30")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_scope_and_two_path_params" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "missing_parameter",
                     "message" => "missing parameter shape in query",
                     "parameter" => "shape"
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "optional query params can be omitted", %{conn: conn} do
      # The shape query param is required, but other ones are not so we do not
      # give them.

      conn =
        get_reply(conn, ~p"/generated/params/some-slug/s/square/t/light/c/red?shape=10", fn conn,
                                                                                            params ->
          # standard phoenix behaviour should not be changed, the path params have priority
          assert %{
                   "slug" => "some-slug",
                   "shape" => "square",
                   "theme" => "light",
                   "color" => "red"
                 } == params

          assert %{"shape" => "10"} == conn.query_params

          # moonwalk data is properly cast
          assert %{shape: 10} == conn.private.moonwalk.query_params

          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end
  end

  describe "generic parameter types" do
    test "valid parameters of different types", %{conn: conn} do
      conn =
        get_reply(
          conn,
          ~p"/generated/params/some-slug/generic?string_param=hello&boolean_param=true&integer_param=42&number_param=99",
          fn conn, params ->
            # Assert that Phoenix doesn't cast the parameters
            assert %{
                     "slug" => "some-slug",
                     "string_param" => "hello",
                     "boolean_param" => "true",
                     "integer_param" => "42",
                     "number_param" => "99"
                   } == params

            assert %{
                     "string_param" => "hello",
                     "boolean_param" => "true",
                     "integer_param" => "42",
                     "number_param" => "99"
                   } == conn.query_params

            # Assert that Moonwalk properly casts the parameters
            assert %{
                     string_param: "hello",
                     boolean_param: true,
                     integer_param: 42,
                     number_param: 99
                   } == conn.private.moonwalk.query_params

            json(conn, %{data: "ok"})
          end
        )

      assert %{"data" => "ok"} = json_response(conn, 200)
    end

    test "invalid parameters that cannot be cast", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/generated/params/some-slug/generic?string_param=hello&boolean_param=not-a-boolean&integer_param=not-a-number&number_param=not-a-number"
        )

      assert %{
               "error" => %{
                 "operation_id" => "param_generic_param_types" <> _,
                 "message" => "Bad Request",
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter boolean_param in query",
                     "parameter" => "boolean_param",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter integer_param in query",
                     "parameter" => "integer_param",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter number_param in query",
                     "parameter" => "number_param",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } =
               json_response(conn, 400)
    end
  end

  describe "array parameters" do
    test "valid array parameters", %{conn: conn} do
      conn =
        get_reply(
          conn,
          ~p"/generated/params/some-slug/arrays?numbers[]=123&numbers[]=456&names[]=Alice&names[]=Bob",
          fn conn, params ->
            # Assert that Phoenix doesn't cast the parameters
            assert %{
                     "slug" => "some-slug",
                     "numbers" => ["123", "456"],
                     "names" => ["Alice", "Bob"]
                   } == params

            assert %{
                     "numbers" => ["123", "456"],
                     "names" => ["Alice", "Bob"]
                   } == conn.query_params

            # Assert that Moonwalk properly casts the parameters
            assert %{
                     numbers: [123, 456],
                     names: ["Alice", "Bob"]
                   } == conn.private.moonwalk.query_params

            # This operation is defined above the slug common parameter, so
            # it's not there
            assert %{} == conn.private.moonwalk.path_params

            json(conn, %{data: "ok"})
          end
        )

      assert %{"data" => "ok"} = json_response(conn, 200)
    end

    test "invalid array parameters", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/generated/params/some-slug/arrays?numbers[]=not-a-number&numbers[]=456&names[]=Alice&names[]=123"
        )

      assert %{
               "error" => %{
                 "operation_id" => "param_array_types" <> _,
                 "message" => "Bad Request",
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter numbers in query",
                     "parameter" => "numbers",
                     "validation_error" => _
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "non-array parameter when array expected", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/arrays?numbers=123&names=Alice")

      assert %{
               "error" => %{
                 "operation_id" => "param_array_types" <> _,
                 "message" => "Bad Request",
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter names in query",
                     "parameter" => "names",
                     "validation_error" => _
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter numbers in query",
                     "parameter" => "numbers",
                     "validation_error" => _
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "array parameters sent to non-array route", %{conn: conn} do
      # Sending array parameters to the generic param route which expects scalar types
      conn =
        get(conn, ~p"/generated/params/some-slug/generic?string_param[]=hello&integer_param[]=42")

      assert %{
               "error" => %{
                 "operation_id" => "param_generic_param_types" <> _,
                 "message" => "Bad Request",
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter integer_param in query",
                     "parameter" => "integer_param",
                     "validation_error" => _
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter string_param in query",
                     "parameter" => "string_param",
                     "validation_error" => _
                   }
                 ]
               }
             } = json_response(conn, 400)
    end
  end

  describe "boolean schema false in query params" do
    test "any query param value should be rejected with boolean schema false", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/boolean-schema-false?reject_me=any_value")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_boolean_schema_false" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter reject_me in query",
                     "parameter" => "reject_me",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "empty string query param should be rejected with boolean schema false", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/boolean-schema-false?reject_me=")

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_boolean_schema_false" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter reject_me in query",
                     "parameter" => "reject_me",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "multiple query params should all be rejected with boolean schema false", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/generated/params/some-slug/boolean-schema-false?reject_me=value1&also_reject=value2"
        )

      assert %{
               "error" => %{
                 "message" => "Bad Request",
                 "operation_id" => "param_boolean_schema_false" <> _,
                 "in" => "parameters",
                 "parameters_errors" => [
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter also_reject in query",
                     "parameter" => "also_reject",
                     "validation_error" => %{"valid" => false}
                   },
                   %{
                     "in" => "query",
                     "kind" => "invalid_parameter",
                     "message" => "invalid parameter reject_me in query",
                     "parameter" => "reject_me",
                     "validation_error" => %{"valid" => false}
                   }
                 ]
               }
             } = json_response(conn, 400)
    end

    test "no query params should be accepted with boolean schema false", %{conn: conn} do
      conn =
        get_reply(conn, ~p"/generated/params/some-slug/boolean-schema-false", fn conn, _params ->
          # No query params should be set or an empty map
          assert conn.private.moonwalk.query_params == %{}

          json(conn, %{data: "ok"})
        end)

      assert %{"data" => "ok"} = json_response(conn, 200)
    end
  end

  describe "html error rendering" do
    @describetag [req_accept: "text/html"]

    test "required query param is missing HTML", %{conn: conn} do
      # The shape query param is required
      conn = get(conn, ~p"/generated/params/some-slug/s/square/t/light/c/red?theme=20&color=30")

      body = response(conn, 400)
      assert body =~ ~r{<!doctype html>.+Bad Request}s

      assert body =~
               ~r{<p>Invalid request for operation <code>param_scope_and_two_path_params_.+</code>.</p>}s

      assert body =~
               ~r{<h2>Missing required parameter <code>shape</code> in <code>query</code>\.</h2>}s

      assert body =~
               "<h2>Missing required parameter <code>shape</code> in <code>query</code>.</h2>"
    end

    test "invalid param text errors", %{conn: conn} do
      conn = get(conn, ~p"/generated/params/some-slug/t/UNKNOWN_THEME")

      body = response(conn, 400)
      assert body =~ ~r{<!doctype html>.+Bad Request}s

      assert body =~
               ~r{<p>Invalid request for operation <code>param_single_path_param_.+</code>.</p>}s

      assert body =~ ~r{<h2>Invalid parameter <code>theme</code> in <code>path</code>\.</h2>}s
      assert body =~ "<h2>Invalid parameter <code>theme</code> in <code>path</code>.</h2>"
      assert body =~ ~S(value must be one of the enum values: "dark" or "light")
    end
  end
end
