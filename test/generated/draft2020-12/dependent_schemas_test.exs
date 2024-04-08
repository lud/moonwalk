defmodule Elixir.Moonwalk.Generated.Draft202012.DependentSchemasTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/dependentSchemas.json
  """

  describe "single dependency ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentSchemas" => %{
          "bar" => %{
            "properties" => %{
              "bar" => %{"type" => "integer"},
              "foo" => %{"type" => "integer"}
            }
          }
        }
      }

      {:ok, schema: schema}
    end

    test "valid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "no dependency", %{schema: schema} do
      data = %{"foo" => "quux"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong type", %{schema: schema} do
      data = %{"bar" => 2, "foo" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong type other", %{schema: schema} do
      data = %{"bar" => "quux", "foo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong type both", %{schema: schema} do
      data = %{"bar" => "quux", "foo" => "quux"}
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

  describe "boolean subschemas ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentSchemas" => %{"bar" => false, "foo" => true}
      }

      {:ok, schema: schema}
    end

    test "object with property having schema true is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with property having schema false is invalid", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with both properties is invalid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "dependencies with escaped characters ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentSchemas" => %{
          "foo\tbar" => %{"minProperties" => 4},
          "foo'bar" => %{"required" => ["foo\"bar"]}
        }
      }

      {:ok, schema: schema}
    end

    test "quoted tab", %{schema: schema} do
      data = %{"a" => 2, "b" => 3, "c" => 4, "foo\tbar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "quoted quote", %{schema: schema} do
      data = %{"foo'bar" => %{"foo\"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "quoted tab invalid under dependent schema", %{schema: schema} do
      data = %{"a" => 2, "foo\tbar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "quoted quote invalid under dependent schema", %{schema: schema} do
      data = %{"foo'bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "dependent subschema incompatible with root ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "dependentSchemas" => %{
          "foo" => %{"additionalProperties" => false, "properties" => %{"bar" => %{}}}
        },
        "properties" => %{"foo" => %{}}
      }

      {:ok, schema: schema}
    end

    test "matches root", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "matches dependency", %{schema: schema} do
      data = %{"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "matches both", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "no dependency", %{schema: schema} do
      data = %{"baz" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
