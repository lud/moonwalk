defmodule Elixir.Moonwalk.Generated.Draft202012.ExclusiveMaximumTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/exclusiveMaximum.json
  """

  describe "exclusiveMaximum validation" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "exclusiveMaximum" => 3.0
      }

      {:ok, schema: schema}
    end

    test "below the exclusiveMaximum is valid", %{schema: schema} do
      data = 2.2
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boundary point is invalid", %{schema: schema} do
      data = 3.0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "above the exclusiveMaximum is invalid", %{schema: schema} do
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
end
