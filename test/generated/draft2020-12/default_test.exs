defmodule Elixir.Moonwalk.Generated.Draft202012.DefaultTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/default.json
  """

  describe "invalid type for default" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"default" => [], "type" => "integer"}}
      }

      {:ok, schema: schema}
    end

    test "valid when property is specified", %{schema: schema} do
      data = %{"foo" => 13}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "still valid when the invalid default is used", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "invalid string value for default" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "bar" => %{"default" => "bad", "minLength" => 4, "type" => "string"}
        }
      }

      {:ok, schema: schema}
    end

    test "valid when property is specified", %{schema: schema} do
      data = %{"bar" => "good"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "still valid when the invalid default is used", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "the default keyword does not do anything if the property is missing" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "alpha" => %{"default" => 5, "maximum" => 3, "type" => "number"}
        },
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "an explicit property value is checked against maximum (passing)", %{schema: schema} do
      data = %{"alpha" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an explicit property value is checked against maximum (failing)", %{schema: schema} do
      data = %{"alpha" => 5}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing properties are not filled in with the default", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
