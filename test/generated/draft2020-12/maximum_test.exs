defmodule Elixir.Moonwalk.Generated.Draft202012.MaximumTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "maximum validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "maximum" => 3.0}
      {:ok, schema: schema}
    end

    test "below the maximum is valid", %{schema: schema} do
      data = 2.6
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point is valid", %{schema: schema} do
      data = 3.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "above the maximum is invalid", %{schema: schema} do
      data = 3.5
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-numbers", %{schema: schema} do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maximum validation with unsigned integer" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "maximum" => 300}
      {:ok, schema: schema}
    end

    test "below the maximum is invalid", %{schema: schema} do
      data = 299.97
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point integer is valid", %{schema: schema} do
      data = 300
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point float is valid", %{schema: schema} do
      data = 300.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "above the maximum is invalid", %{schema: schema} do
      data = 300.5
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
