defmodule Elixir.Moonwalk.Generated.Draft202012.MinItemsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "minItems validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minItems" => 1}
      {:ok, schema: schema}
    end

    test "longer is valid", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "exact length is valid", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too short is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-arrays", %{schema: schema} do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minItems validation with a decimal" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "minItems" => 1.0
      }

      {:ok, schema: schema}
    end

    test "longer is valid", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too short is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
