defmodule Elixir.Moonwalk.Generated.Draft202012.PatternTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "pattern validation" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "pattern" => "^a*$"
      }

      {:ok, schema: schema}
    end

    test "a matching pattern is valid", %{schema: schema} do
      data = "aaa"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-matching pattern is invalid", %{schema: schema} do
      data = "abc"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores booleans", %{schema: schema} do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores integers", %{schema: schema} do
      data = 123
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores floats", %{schema: schema} do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores null", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "pattern is not anchored" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "pattern" => "a+"
      }

      {:ok, schema: schema}
    end

    test "matches a substring", %{schema: schema} do
      data = "xxaayy"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
