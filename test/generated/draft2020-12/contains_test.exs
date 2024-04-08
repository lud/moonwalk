defmodule Elixir.Moonwalk.Generated.Draft202012.ContainsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/contains.json
  """

  describe "contains keyword validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"minimum" => 5}
      }

      {:ok, schema: schema}
    end

    test "array with item matching schema (5) is valid", %{schema: schema} do
      data = [3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array with item matching schema (6) is valid", %{schema: schema} do
      data = [3, 4, 6]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array with two items matching schema (5, 6) is valid", %{schema: schema} do
      data = [3, 4, 5, 6]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array without items matching schema is invalid", %{schema: schema} do
      data = [2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "not array is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "contains keyword with const keyword ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 5}
      }

      {:ok, schema: schema}
    end

    test "array with item 5 is valid", %{schema: schema} do
      data = [3, 4, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array with two items 5 is valid", %{schema: schema} do
      data = [3, 4, 5, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array without item 5 is invalid", %{schema: schema} do
      data = [1, 2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "contains keyword with boolean schema true ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => true
      }

      {:ok, schema: schema}
    end

    test "any non-empty array is valid", %{schema: schema} do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "contains keyword with boolean schema false ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => false
      }

      {:ok, schema: schema}
    end

    test "any non-empty array is invalid", %{schema: schema} do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "non-arrays are valid", %{schema: schema} do
      data = "contains does not apply to strings"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items + contains ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"multipleOf" => 3},
        "items" => %{"multipleOf" => 2}
      }

      {:ok, schema: schema}
    end

    test "matches items, does not match contains", %{schema: schema} do
      data = [2, 4, 8]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "does not match items, matches contains", %{schema: schema} do
      data = [3, 6, 9]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "matches both items and contains", %{schema: schema} do
      data = [6, 12]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "matches neither items nor contains", %{schema: schema} do
      data = [1, 5]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "contains with false if subschema ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"else" => true, "if" => false}
      }

      {:ok, schema: schema}
    end

    test "any non-empty array is valid", %{schema: schema} do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "contains with null instance elements ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"type" => "null"}
      }

      {:ok, schema: schema}
    end

    test "allows null items", %{schema: schema} do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
