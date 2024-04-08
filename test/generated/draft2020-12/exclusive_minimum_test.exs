defmodule Elixir.Moonwalk.Generated.Draft202012.ExclusiveMinimumTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/exclusiveMinimum.json
  """

  describe "exclusiveMinimum validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "exclusiveMinimum" => 1.1
      }

      {:ok, schema: schema}
    end

    test "above the exclusiveMinimum is valid", %{schema: schema} do
      data = 1.2
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point is invalid", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "below the exclusiveMinimum is invalid", %{schema: schema} do
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
end
