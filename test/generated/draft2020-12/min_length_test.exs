defmodule Elixir.Moonwalk.Generated.Draft202012.MinLengthTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minLength.json
  """

  describe "minLength validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minLength" => 2}
      {:ok, schema: schema}
    end

    test "longer is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "exact length is valid", %{schema: schema} do
      data = "fo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too short is invalid", %{schema: schema} do
      data = "f"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-strings", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "one grapheme is not long enough", %{schema: schema} do
      data = "💩"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "minLength validation with a decimal" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "minLength" => 2.0
      }

      {:ok, schema: schema}
    end

    test "longer is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too short is invalid", %{schema: schema} do
      data = "f"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
