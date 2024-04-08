defmodule Elixir.Moonwalk.Generated.Draft202012.NotTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/not.json
  """

  describe "not ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "not" => %{"type" => "integer"}
      }

      {:ok, schema: schema}
    end

    test "allowed", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "disallowed", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "not multiple types ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "not" => %{"type" => ["integer", "boolean"]}
      }

      {:ok, schema: schema}
    end

    test "valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "other mismatch", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "not more complex schema ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "not" => %{
          "properties" => %{"foo" => %{"type" => "string"}},
          "type" => "object"
        }
      }

      {:ok, schema: schema}
    end

    test "match", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "other match", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "forbidden property ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"not" => %{}}}
      }

      {:ok, schema: schema}
    end

    test "property present", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "property absent", %{schema: schema} do
      data = %{"bar" => 1, "baz" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "forbid everything with empty schema ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "not" => %{}}
      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean true is invalid", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean false is invalid", %{schema: schema} do
      data = false
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is invalid", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is invalid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array is invalid", %{schema: schema} do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "forbid everything with boolean schema true ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "not" => true}
      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean true is invalid", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean false is invalid", %{schema: schema} do
      data = false
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is invalid", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is invalid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array is invalid", %{schema: schema} do
      data = ["foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "allow everything with boolean schema false ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "not" => false}
      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean true is valid", %{schema: schema} do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean false is valid", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array is valid", %{schema: schema} do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is valid", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "double negation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "not" => %{"not" => %{}}
      }

      {:ok, schema: schema}
    end

    test "any value is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "collect annotations inside a 'not', even if collection is disabled ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "not" => %{
          "$comment" =>
            "this subschema must still produce annotations internally, even though the 'not' will ultimately discard them",
          "anyOf" => [true, %{"properties" => %{"foo" => true}}],
          "unevaluatedProperties" => false
        }
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "unevaluated property", %{schema: schema} do
      data = %{"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "annotations are still collected inside a 'not'", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
