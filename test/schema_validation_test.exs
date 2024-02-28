defmodule Moonwalk.SchemaValidationTest do
  alias Moonwalk.Test.JsonSchemaTestSuite
  use ExUnit.Case, async: true

  @moduletag :json_schema

  # Each json schema "test suite" defined a series of test cases with a schema
  # and an array of "unit tests".

  {:ok, loader} = JsonSchemaTestSuite.load_dir("draft2020-12")

  suites = [
    {"content.json", validate: false},
    {"type.json", []}
  ]

  Enum.each(suites, fn {filename, opts} ->
    suite = JsonSchemaTestSuite.checkout_suite(loader, filename)
    validate? = Keyword.get(opts, :validate, true)

    for test_case <- suite do
      %{"description" => case_descr, "schema" => json_schema, "tests" => tests} = test_case

      describe case_descr do
        setup do
          {:ok, %{test_case: unquote(Macro.escape(test_case))}}
        end

        # If we are not testing the validation we must at least ensure that
        # the schema can be manipulated by the library

        test "schema denormalization", %{test_case: test_case} do
          denorm_schema(Map.fetch!(test_case, "schema"))
        end

        if validate? do
          for %{"description" => test_descr} = unit_test <- tests do
            test test_descr, %{test_case: test_case} do
              unit_test = unquote(Macro.escape(unit_test))
              validation_test(test_case, unit_test)
            end
          end
        end
      end
    end
  end)

  defp denorm_schema(json_schema) do
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
  end

  defp validation_test(test_case, unit_test) do
    %{"schema" => json_schema} = test_case
    %{"data" => data, "valid" => expected_valid, "description" => test_descr} = unit_test

    schema = denorm_schema(json_schema)

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
        #{test_descr}

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

  JsonSchemaTestSuite.stop_warn_unchecked(loader)
end