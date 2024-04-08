defmodule Elixir.Moonwalk.Generated.Draft202012.MaxContainsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/maxContains.json
  """

  describe "maxContains without contains is ignored" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "maxContains" => 1
      }

      {:ok, schema: schema}
    end

    test "one item valid against lone maxContains", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "two items still valid against lone maxContains", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxContains with contains" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "maxContains" => 1
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, valid maxContains", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, invalid maxContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "some elements match, valid maxContains", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "some elements match, invalid maxContains", %{schema: schema} do
      data = [1, 2, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxContains with contains, value with a decimal" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "maxContains" => 1.0
      }

      {:ok, schema: schema}
    end

    test "one element matches, valid maxContains", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too many elements match, invalid maxContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minContains < maxContains" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "maxContains" => 3,
        "minContains" => 1
      }

      {:ok, schema: schema}
    end

    test "actual < minContains < maxContains", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "minContains < actual < maxContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "minContains < maxContains < actual", %{schema: schema} do
      data = [1, 1, 1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
