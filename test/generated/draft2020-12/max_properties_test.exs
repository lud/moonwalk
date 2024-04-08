defmodule Elixir.Moonwalk.Generated.Draft202012.MaxPropertiesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/maxProperties.json
  """

  describe "maxProperties validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "maxProperties" => 2
      }

      {:ok, schema: schema}
    end

    test "shorter is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "exact length is valid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too long is invalid", %{schema: schema} do
      data = %{"bar" => 2, "baz" => 3, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = [1, 2, 3]
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

  describe "maxProperties validation with a decimal ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "maxProperties" => 2.0
      }

      {:ok, schema: schema}
    end

    test "shorter is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too long is invalid", %{schema: schema} do
      data = %{"bar" => 2, "baz" => 3, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "maxProperties = 0 means the object is empty ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "maxProperties" => 0
      }

      {:ok, schema: schema}
    end

    test "no properties is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "one property is invalid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
