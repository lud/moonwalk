defmodule Elixir.Moonwalk.Generated.Draft202012.MinPropertiesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minProperties.json
  """

  describe "minProperties validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "minProperties" => 1
      }

      {:ok, schema: schema}
    end

    test "longer is valid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "exact length is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too short is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores strings", %{schema: schema} do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minProperties validation with a decimal ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "minProperties" => 1.0
      }

      {:ok, schema: schema}
    end

    test "longer is valid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too short is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
