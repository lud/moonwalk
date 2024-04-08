defmodule Elixir.Moonwalk.Generated.Draft202012.MinContainsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minContains.json
  """

  describe "minContains without contains is ignored ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "minContains" => 1
      }

      {:ok, schema: schema}
    end

    test "one item valid against lone minContains", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "zero items still valid against lone minContains", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minContains=1 with contains ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "minContains" => 1
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "no elements match", %{schema: schema} do
      data = [2]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "single element matches, valid minContains", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "some elements match, valid minContains", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, valid minContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minContains=2 with contains ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "minContains" => 2
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, invalid minContains", %{schema: schema} do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "some elements match, invalid minContains", %{schema: schema} do
      data = [1, 2]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, valid minContains (exactly as needed)", %{schema: schema} do
      data = [1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, valid minContains (more than needed)", %{schema: schema} do
      data = [1, 1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "some elements match, valid minContains", %{schema: schema} do
      data = [1, 2, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minContains=2 with contains with a decimal value ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "minContains" => 2.0
      }

      {:ok, schema: schema}
    end

    test "one element matches, invalid minContains", %{schema: schema} do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both elements match, valid minContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxContains = minContains ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "maxContains" => 2,
        "minContains" => 2
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, invalid minContains", %{schema: schema} do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, invalid maxContains", %{schema: schema} do
      data = [1, 1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all elements match, valid maxContains and minContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxContains < minContains ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "maxContains" => 1,
        "minContains" => 3
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid minContains", %{schema: schema} do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid maxContains", %{schema: schema} do
      data = [1, 1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid maxContains and minContains", %{schema: schema} do
      data = [1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minContains = 0 ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "minContains" => 0
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "minContains = 0 makes contains always pass", %{schema: schema} do
      data = [2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minContains = 0 with maxContains ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contains" => %{"const" => 1},
        "maxContains" => 1,
        "minContains" => 0
      }

      {:ok, schema: schema}
    end

    test "empty data", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "not more than maxContains", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too many", %{schema: schema} do
      data = [1, 1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
