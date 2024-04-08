defmodule Elixir.Moonwalk.Generated.Draft202012.PrefixItemsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "a schema given for prefixItems" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "integer"}, %{"type" => "string"}]
      }

      {:ok, schema: schema}
    end

    test "correct types", %{schema: schema} do
      data = [1, "foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong types", %{schema: schema} do
      data = ["foo", 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "incomplete array of items", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array with additional items", %{schema: schema} do
      data = [1, "foo", true]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "JavaScript pseudo-array is valid", %{schema: schema} do
      data = %{"0" => "invalid", "1" => "valid", "length" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "prefixItems with boolean schemas" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [true, false]
      }

      {:ok, schema: schema}
    end

    test "array with one item is valid", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array with two items is invalid", %{schema: schema} do
      data = [1, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is valid", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "additional items are allowed by default" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "integer"}]
      }

      {:ok, schema: schema}
    end

    test "only the first item is validated", %{schema: schema} do
      data = [1, "foo", false]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "prefixItems with null instance elements" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "null"}]
      }

      {:ok, schema: schema}
    end

    test "allows null elements", %{schema: schema} do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
