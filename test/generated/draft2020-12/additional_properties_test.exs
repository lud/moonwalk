defmodule Elixir.Moonwalk.Generated.Draft202012.AdditionalPropertiesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/additionalProperties.json
  """

  describe "additionalProperties being false does not allow other properties ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => false,
        "patternProperties" => %{"^v" => %{}},
        "properties" => %{"bar" => %{}, "foo" => %{}}
      }

      {:ok, schema: schema}
    end

    test "no additional properties is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an additional property is invalid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1, "quux" => "boom"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores strings", %{schema: schema} do
      data = "foobarbaz"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "patternProperties are not additional properties", %{schema: schema} do
      data = %{"foo" => 1, "vroom" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "non-ASCII pattern with additionalProperties ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => false,
        "patternProperties" => %{"^á" => %{}}
      }

      {:ok, schema: schema}
    end

    test "matching the pattern is valid", %{schema: schema} do
      data = %{"ármányos" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "not matching the pattern is invalid", %{schema: schema} do
      data = %{"élmény" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "additionalProperties with schema ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "boolean"},
        "properties" => %{"bar" => %{}, "foo" => %{}}
      }

      {:ok, schema: schema}
    end

    test "no additional properties is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an additional valid property is valid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an additional invalid property is invalid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1, "quux" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "additionalProperties can exist by itself ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "boolean"}
      }

      {:ok, schema: schema}
    end

    test "an additional valid property is valid", %{schema: schema} do
      data = %{"foo" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an additional invalid property is invalid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "additionalProperties are allowed by default ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"bar" => %{}, "foo" => %{}}
      }

      {:ok, schema: schema}
    end

    test "additional properties are allowed", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1, "quux" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "additionalProperties does not look in applicators ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "boolean"},
        "allOf" => [%{"properties" => %{"foo" => %{}}}]
      }

      {:ok, schema: schema}
    end

    test "properties defined in allOf are not examined", %{schema: schema} do
      data = %{"bar" => true, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "additionalProperties with null valued instance properties ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "null"}
      }

      {:ok, schema: schema}
    end

    test "allows null values", %{schema: schema} do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
