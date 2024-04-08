defmodule Elixir.Moonwalk.Generated.Draft202012.BooleanSchemaTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/boolean_schema.json
  """

  describe "boolean schema 'true' ⋅" do
    setup do
      schema = true
      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean true is valid", %{schema: schema} do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean false is valid", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array is valid", %{schema: schema} do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is valid", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "boolean schema 'false' ⋅" do
    setup do
      schema = false
      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean true is invalid", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean false is invalid", %{schema: schema} do
      data = false
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is invalid", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is invalid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array is invalid", %{schema: schema} do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
