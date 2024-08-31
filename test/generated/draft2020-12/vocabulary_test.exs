# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule Elixir.Moonwalk.Generated.Draft202012.VocabularyTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/vocabulary.json
  """

  describe "schema that uses custom metaschema with with no validation vocabulary:" do
    setup do
      json_schema = %{
        "$id" => "https://schema/using/no/validation",
        "$schema" => "http://localhost:1234/draft2020-12/metaschema-no-validation.json",
        "properties" => %{
          "badProperty" => false,
          "numberProperty" => %{"minimum" => 10}
        }
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "applicator vocabulary still works", c do
      data = %{"badProperty" => "this property should not exist"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no validation: valid number", c do
      data = %{"numberProperty" => 20}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "no validation: invalid number, but it still validates", c do
      data = %{"numberProperty" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "ignore unrecognized optional vocabulary:" do
    setup do
      json_schema = %{
        "$schema" => "http://localhost:1234/draft2020-12/metaschema-optional-vocabulary.json",
        "type" => "number"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "string value", c do
      data = "foobar"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "number value", c do
      data = 20
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
