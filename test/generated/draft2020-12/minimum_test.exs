defmodule Elixir.Moonwalk.Generated.Draft202012.MinimumTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minimum.json
  """

  describe "minimum validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minimum" => 1.1}
      {:ok, schema: schema}
    end

    test "above the minimum is valid", %{schema: schema} do
      data = 2.6
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point is valid", %{schema: schema} do
      data = 1.1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "below the minimum is invalid", %{schema: schema} do
      data = 0.6
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-numbers", %{schema: schema} do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minimum validation with signed integer" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minimum" => -2}
      {:ok, schema: schema}
    end

    test "negative above the minimum is valid", %{schema: schema} do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "positive above the minimum is valid", %{schema: schema} do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point is valid", %{schema: schema} do
      data = -2
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point with float is valid", %{schema: schema} do
      data = -2.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float below the minimum is invalid", %{schema: schema} do
      data = -2.0001
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "int below the minimum is invalid", %{schema: schema} do
      data = -3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-numbers", %{schema: schema} do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
