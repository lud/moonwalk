defmodule Elixir.Moonwalk.Generated.Draft202012.VocabularyTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/vocabulary.json
  """

  describe "schema that uses custom metaschema with with no validation vocabulary" do
    setup do
      schema = %{
        "$id" => "https://schema/using/no/validation",
        "$schema" => "http://localhost:1234/draft2020-12/metaschema-no-validation.json",
        "properties" => %{
          "badProperty" => false,
          "numberProperty" => %{"minimum" => 10}
        }
      }

      {:ok, schema: schema}
    end

    test "applicator vocabulary still works", %{schema: schema} do
      data = %{"badProperty" => "this property should not exist"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "no validation: valid number", %{schema: schema} do
      data = %{"numberProperty" => 20}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "no validation: invalid number, but it still validates", %{schema: schema} do
      data = %{"numberProperty" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ignore unrecognized optional vocabulary" do
    setup do
      schema = %{
        "$schema" => "http://localhost:1234/draft2020-12/metaschema-optional-vocabulary.json",
        "type" => "number"
      }

      {:ok, schema: schema}
    end

    test "string value", %{schema: schema} do
      data = "foobar"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number value", %{schema: schema} do
      data = 20
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
