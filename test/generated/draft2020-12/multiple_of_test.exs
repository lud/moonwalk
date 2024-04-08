defmodule Elixir.Moonwalk.Generated.Draft202012.MultipleOfTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/multipleOf.json
  """

  describe "by int ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "multipleOf" => 2
      }

      {:ok, schema: schema}
    end

    test "int by int", %{schema: schema} do
      data = 10
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "int by int fail", %{schema: schema} do
      data = 7
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-numbers", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "by number ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "multipleOf" => 1.5
      }

      {:ok, schema: schema}
    end

    test "zero is multiple of anything", %{schema: schema} do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "4.5 is multiple of 1.5", %{schema: schema} do
      data = 4.5
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "35 is not multiple of 1.5", %{schema: schema} do
      data = 35
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "by small number ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "multipleOf" => 0.0001
      }

      {:ok, schema: schema}
    end

    test "0.0075 is multiple of 0.0001", %{schema: schema} do
      data = 0.0075
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "0.00751 is not multiple of 0.0001", %{schema: schema} do
      data = 0.00751
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "float division = inf ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "multipleOf" => 0.123456789,
        "type" => "integer"
      }

      {:ok, schema: schema}
    end

    test "always invalid, but naive implementations may raise an overflow error", %{schema: schema} do
      data = 1.0e308
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "small multiple of large integer ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "multipleOf" => 1.0e-8,
        "type" => "integer"
      }

      {:ok, schema: schema}
    end

    test "any integer is a multiple of 1e-8", %{schema: schema} do
      data = 12_391_239_123
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
