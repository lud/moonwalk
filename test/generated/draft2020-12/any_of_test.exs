defmodule Elixir.Moonwalk.Generated.Draft202012.AnyOfTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/anyOf.json
  """

  describe "anyOf" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [%{"type" => "integer"}, %{"minimum" => 2}]
      }

      {:ok, schema: schema}
    end

    test "first anyOf valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "second anyOf valid", %{schema: schema} do
      data = 2.5
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both anyOf valid", %{schema: schema} do
      data = 3
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "neither anyOf valid", %{schema: schema} do
      data = 1.5
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anyOf with base schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [%{"maxLength" => 2}, %{"minLength" => 4}],
        "type" => "string"
      }

      {:ok, schema: schema}
    end

    test "mismatch base schema", %{schema: schema} do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "one anyOf valid", %{schema: schema} do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both anyOf invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anyOf with boolean schemas, all true" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [true, true]
      }

      {:ok, schema: schema}
    end

    test "any value is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anyOf with boolean schemas, some true" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [true, false]
      }

      {:ok, schema: schema}
    end

    test "any value is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anyOf with boolean schemas, all false" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [false, false]
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anyOf complex types" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [
          %{"properties" => %{"bar" => %{"type" => "integer"}}, "required" => ["bar"]},
          %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]}
        ]
      }

      {:ok, schema: schema}
    end

    test "first anyOf valid (complex)", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "second anyOf valid (complex)", %{schema: schema} do
      data = %{"foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both anyOf valid (complex)", %{schema: schema} do
      data = %{"bar" => 2, "foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "neither anyOf valid (complex)", %{schema: schema} do
      data = %{"bar" => "quux", "foo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anyOf with one empty schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [%{"type" => "number"}, %{}]
      }

      {:ok, schema: schema}
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number is valid", %{schema: schema} do
      data = 123
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nested anyOf, to check validation semantics" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "anyOf" => [%{"anyOf" => [%{"type" => "null"}]}]
      }

      {:ok, schema: schema}
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "anything non-null is invalid", %{schema: schema} do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
