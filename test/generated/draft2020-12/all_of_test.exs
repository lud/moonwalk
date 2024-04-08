defmodule Elixir.Moonwalk.Generated.Draft202012.AllOfTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/allOf.json
  """

  describe "allOf" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"properties" => %{"bar" => %{"type" => "integer"}}, "required" => ["bar"]},
          %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]}
        ]
      }

      {:ok, schema: schema}
    end

    test "allOf", %{schema: schema} do
      data = %{"bar" => 2, "foo" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch second", %{schema: schema} do
      data = %{"foo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch first", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong type", %{schema: schema} do
      data = %{"bar" => "quux", "foo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with base schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]},
          %{"properties" => %{"baz" => %{"type" => "null"}}, "required" => ["baz"]}
        ],
        "properties" => %{"bar" => %{"type" => "integer"}},
        "required" => ["bar"]
      }

      {:ok, schema: schema}
    end

    test "valid", %{schema: schema} do
      data = %{"bar" => 2, "baz" => nil, "foo" => "quux"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch base schema", %{schema: schema} do
      data = %{"baz" => nil, "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch first allOf", %{schema: schema} do
      data = %{"bar" => 2, "baz" => nil}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch second allOf", %{schema: schema} do
      data = %{"bar" => 2, "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch both", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf simple types" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"maximum" => 30}, %{"minimum" => 20}]
      }

      {:ok, schema: schema}
    end

    test "valid", %{schema: schema} do
      data = 25
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch one", %{schema: schema} do
      data = 35
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with boolean schemas, all true" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [true, true]
      }

      {:ok, schema: schema}
    end

    test "any value is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with boolean schemas, some false" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [true, false]
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with boolean schemas, all false" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [false, false]
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with one empty schema" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "allOf" => [%{}]}
      {:ok, schema: schema}
    end

    test "any data is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with two empty schemas" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{}, %{}]
      }

      {:ok, schema: schema}
    end

    test "any data is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with the first empty schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{}, %{"type" => "number"}]
      }

      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allOf with the last empty schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"type" => "number"}, %{}]
      }

      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nested allOf, to check validation semantics" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"allOf" => [%{"type" => "null"}]}]
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

  describe "allOf combined with anyOf, oneOf" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"multipleOf" => 2}],
        "anyOf" => [%{"multipleOf" => 3}],
        "oneOf" => [%{"multipleOf" => 5}]
      }

      {:ok, schema: schema}
    end

    test "allOf: false, anyOf: false, oneOf: false", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: false, anyOf: false, oneOf: true", %{schema: schema} do
      data = 5
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: false, anyOf: true, oneOf: false", %{schema: schema} do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: false, anyOf: true, oneOf: true", %{schema: schema} do
      data = 15
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: true, anyOf: false, oneOf: false", %{schema: schema} do
      data = 2
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: true, anyOf: false, oneOf: true", %{schema: schema} do
      data = 10
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: true, anyOf: true, oneOf: false", %{schema: schema} do
      data = 6
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "allOf: true, anyOf: true, oneOf: true", %{schema: schema} do
      data = 30
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
