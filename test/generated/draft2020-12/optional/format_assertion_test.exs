# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule Elixir.Moonwalk.Generated.Draft202012.Optional.FormatAssertionTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format-assertion.json
  """

  describe "schema that uses custom metaschema with format-assertion: false:" do
    setup do
      json_schema = %{
        "$id" => "https://schema/using/format-assertion/false",
        "$schema" => "http://localhost:1234/draft2020-12/format-assertion-false.json",
        "format" => "ipv4"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "format-assertion: false: valid string", c do
      data = "127.0.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "format-assertion: false: invalid string", c do
      data = "not-an-ipv4"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "schema that uses custom metaschema with format-assertion: true:" do
    setup do
      json_schema = %{
        "$id" => "https://schema/using/format-assertion/true",
        "$schema" => "http://localhost:1234/draft2020-12/format-assertion-true.json",
        "format" => "ipv4"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "format-assertion: true: valid string", c do
      data = "127.0.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "format-assertion: true: invalid string", c do
      data = "not-an-ipv4"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
