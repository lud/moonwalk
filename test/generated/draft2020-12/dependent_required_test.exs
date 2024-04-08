defmodule Elixir.Moonwalk.Generated.Draft202012.DependentRequiredTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/dependentRequired.json
  """

  describe "single dependency" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentRequired" => %{"bar" => ["foo"]}
      }

      {:ok, schema: schema}
    end

    test "neither", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "nondependant", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "with dependency", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing dependency", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = ["bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores strings", %{schema: schema} do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "empty dependents" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentRequired" => %{"bar" => []}
      }

      {:ok, schema: schema}
    end

    test "empty object", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with one property", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "non-object is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "multiple dependents required" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentRequired" => %{"quux" => ["foo", "bar"]}
      }

      {:ok, schema: schema}
    end

    test "neither", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "nondependants", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "with dependencies", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1, "quux" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing dependency", %{schema: schema} do
      data = %{"foo" => 1, "quux" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing other dependency", %{schema: schema} do
      data = %{"bar" => 1, "quux" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing both dependencies", %{schema: schema} do
      data = %{"quux" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "dependencies with escaped characters" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentRequired" => %{
          "foo\nbar" => ["foo\rbar"],
          "foo\"bar" => ["foo'bar"]
        }
      }

      {:ok, schema: schema}
    end

    test "CRLF", %{schema: schema} do
      data = %{"foo\nbar" => 1, "foo\rbar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "quoted quotes", %{schema: schema} do
      data = %{"foo\"bar" => 2, "foo'bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "CRLF missing dependent", %{schema: schema} do
      data = %{"foo" => 2, "foo\nbar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "quoted quotes missing dependent", %{schema: schema} do
      data = %{"foo\"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
