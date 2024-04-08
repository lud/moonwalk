defmodule Elixir.Moonwalk.Generated.Draft202012.IfThenElseTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/if-then-else.json
  """

  describe "ignore if without then or else ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{"const" => 0}
      }

      {:ok, schema: schema}
    end

    test "valid when valid against lone if", %{schema: schema} do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid when invalid against lone if", %{schema: schema} do
      data = "hello"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ignore then without if ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "then" => %{"const" => 0}
      }

      {:ok, schema: schema}
    end

    test "valid when valid against lone then", %{schema: schema} do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid when invalid against lone then", %{schema: schema} do
      data = "hello"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ignore else without if ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"const" => 0}
      }

      {:ok, schema: schema}
    end

    test "valid when valid against lone else", %{schema: schema} do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid when invalid against lone else", %{schema: schema} do
      data = "hello"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "if and then without else ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{"exclusiveMaximum" => 0},
        "then" => %{"minimum" => -10}
      }

      {:ok, schema: schema}
    end

    test "valid through then", %{schema: schema} do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid through then", %{schema: schema} do
      data = -100
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid when if test fails", %{schema: schema} do
      data = 3
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "if and else without then ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"multipleOf" => 2},
        "if" => %{"exclusiveMaximum" => 0}
      }

      {:ok, schema: schema}
    end

    test "valid when if test passes", %{schema: schema} do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid through else", %{schema: schema} do
      data = 4
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid through else", %{schema: schema} do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "validate against correct branch, then vs else ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"multipleOf" => 2},
        "if" => %{"exclusiveMaximum" => 0},
        "then" => %{"minimum" => -10}
      }

      {:ok, schema: schema}
    end

    test "valid through then", %{schema: schema} do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid through then", %{schema: schema} do
      data = -100
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid through else", %{schema: schema} do
      data = 4
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid through else", %{schema: schema} do
      data = 3
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "non-interference across combined schemas ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"if" => %{"exclusiveMaximum" => 0}},
          %{"then" => %{"minimum" => -10}},
          %{"else" => %{"multipleOf" => 2}}
        ]
      }

      {:ok, schema: schema}
    end

    test "valid, but would have been invalid through then", %{schema: schema} do
      data = -100
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid, but would have been invalid through else", %{schema: schema} do
      data = 3
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "if with boolean schema true ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"const" => "else"},
        "if" => true,
        "then" => %{"const" => "then"}
      }

      {:ok, schema: schema}
    end

    test "boolean schema true in if always chooses the then path (valid)", %{schema: schema} do
      data = "then"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean schema true in if always chooses the then path (invalid)", %{schema: schema} do
      data = "else"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "if with boolean schema false ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"const" => "else"},
        "if" => false,
        "then" => %{"const" => "then"}
      }

      {:ok, schema: schema}
    end

    test "boolean schema false in if always chooses the else path (invalid)", %{schema: schema} do
      data = "then"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "boolean schema false in if always chooses the else path (valid)", %{schema: schema} do
      data = "else"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "if appears at the end when serialized (keyword processing sequence) ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"const" => "other"},
        "if" => %{"maxLength" => 4},
        "then" => %{"const" => "yes"}
      }

      {:ok, schema: schema}
    end

    test "yes redirects to then and passes", %{schema: schema} do
      data = "yes"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "other redirects to else and passes", %{schema: schema} do
      data = "other"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "no redirects to then and fails", %{schema: schema} do
      data = "no"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid redirects to else and fails", %{schema: schema} do
      data = "invalid"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
