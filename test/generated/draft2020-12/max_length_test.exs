defmodule Elixir.Moonwalk.Generated.Draft202012.MaxLengthTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "maxLength validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "maxLength" => 2}
      {:ok, schema: schema}
    end

    test "shorter is valid", %{schema: schema} do
      data = "f"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "exact length is valid", %{schema: schema} do
      data = "fo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too long is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-strings", %{schema: schema} do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "two graphemes is long enough", %{schema: schema} do
      data = "💩💩"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxLength validation with a decimal" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "maxLength" => 2.0
      }

      {:ok, schema: schema}
    end

    test "shorter is valid", %{schema: schema} do
      data = "f"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too long is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
