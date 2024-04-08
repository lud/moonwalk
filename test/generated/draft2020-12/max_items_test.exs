defmodule Elixir.Moonwalk.Generated.Draft202012.MaxItemsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/maxItems.json
  """

  describe "maxItems validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "maxItems" => 2}
      {:ok, schema: schema}
    end

    test "shorter is valid", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "exact length is valid", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too long is invalid", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-arrays", %{schema: schema} do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxItems validation with a decimal" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "maxItems" => 2.0
      }

      {:ok, schema: schema}
    end

    test "shorter is valid", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too long is invalid", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
