defmodule Moonwalk.SchemaValidationTest do
  alias Moonwalk.Test.JsonSchemaTestSuite
  use ExUnit.Case, async: true

  @moduletag :json_schema

  # Each json schema "test suite" defined a series of test cases with a schema
  # and an array of "unit tests".

  {:ok, loader} = JsonSchemaTestSuite.load_dir("draft2020-12")

  suites = ["type.json"]

  Enum.each(suites, fn filename ->
    suite = JsonSchemaTestSuite.checkout_suite(loader, filename)

    for test_case <- suite do
      %{"description" => case_descr, "schema" => json_schema, "tests" => tests} = test_case

      describe case_descr do
        setup do
          json_schema = unquote(Macro.escape(json_schema))
          {:ok, %{json_schema: json_schema}}
        end

        for test <- tests do
          %{"data" => data, "description" => test_descr, "valid" => expected_valid} = test

          test test_descr, %{json_schema: json_schema} do
            data = unquote(Macro.escape(data))
            expected_valid = unquote(expected_valid)

            # test that we can import the schema in moonwalk structs
            schema =
              case Moonwalk.Schema.denormalize(json_schema) do
                {:ok, schema} ->
                  schema

                {:error, error} ->
                  flunk("""
                  Failed to denormalize schema: #{inspect(error)}

                  SCHEMA
                  #{inspect(json_schema, pretty: true)}
                  """)
              end

            {valid?, errors} =
              case Moonwalk.Schema.validate(data, schema) do
                {:ok, _} -> {true, nil}
                {:error, errors} -> {false, errors}
              end

            # assert the expected result

            case valid? do
              ^expected_valid ->
                :ok

              other ->
                flunk("""
                #{if expected_valid, do: "Expected valid, got errors", else: "Expected errors, got valid"}

                CASE
                #{unquote(test_descr)}

                JSON SCHEMA
                #{inspect(json_schema, pretty: true)}

                SCHEMA
                #{inspect(schema, pretty: true)}

                DATA
                #{inspect(data, pretty: true)}

                ERRORS
                #{inspect(errors, pretty: true)}
                """)
            end
          end
        end
      end
    end

    # for %{"description" => suite_descr, "schema" => json_schema, "tests" => tests} <- suites do

    #   describe suite do
    #     for tcase <- JsonSchemaTestSuite.suite_cases(suite)    do

    #       test "case: #{subpath}", %{agent: agent} do
    #         path = JsonSchemaTestSuite.checkout_file(agent, unquote(subpath))
    #         JsonSchemaTestSuite.run_file(path, :draft4)
    #       end
    #     end
    #   end

    # end
  end)

  JsonSchemaTestSuite.stop_warn_unchecked(loader)
end
