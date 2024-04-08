defmodule Elixir.Moonwalk.Generated.Draft202012.ContentTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/content.json
  """

  describe "validation of string-encoded content based on media type" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contentMediaType" => "application/json"
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "a valid JSON document", %{schema: schema} do
      data = "{\"foo\": \"bar\"}"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an invalid JSON document; validates true", %{schema: schema} do
      data = "{:}"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "ignores non-strings", %{schema: schema} do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "validation of binary string-encoding" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contentEncoding" => "base64"
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "a valid base64 string", %{schema: schema} do
      data = "eyJmb28iOiAiYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an invalid base64 string (% is not a valid character); validates true", %{schema: schema} do
      data = "eyJmb28iOi%iYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "ignores non-strings", %{schema: schema} do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "validation of binary-encoded media type documents" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contentEncoding" => "base64",
        "contentMediaType" => "application/json"
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "a valid base64-encoded JSON document", %{schema: schema} do
      data = "eyJmb28iOiAiYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "a validly-encoded invalid JSON document; validates true", %{schema: schema} do
      data = "ezp9Cg=="
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an invalid base64 string that is valid JSON; validates true", %{schema: schema} do
      data = "{}"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "ignores non-strings", %{schema: schema} do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "validation of binary-encoded media type documents with schema" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "contentEncoding" => "base64",
        "contentMediaType" => "application/json",
        "contentSchema" => %{
          "properties" => %{"foo" => %{"type" => "string"}},
          "required" => ["foo"],
          "type" => "object"
        }
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "a valid base64-encoded JSON document", %{schema: schema} do
      data = "eyJmb28iOiAiYmFyIn0K"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "another valid base64-encoded JSON document", %{schema: schema} do
      data = "eyJib28iOiAyMCwgImZvbyI6ICJiYXoifQ=="
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an invalid base64-encoded JSON document; validates true", %{schema: schema} do
      data = "eyJib28iOiAyMH0="
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an empty object as a base64-encoded JSON document; validates true", %{schema: schema} do
      data = "e30="
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an empty array as a base64-encoded JSON document", %{schema: schema} do
      data = "W10="
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "a validly-encoded invalid JSON document; validates true", %{schema: schema} do
      data = "ezp9Cg=="
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "an invalid base64 string that is valid JSON; validates true", %{schema: schema} do
      data = "{}"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "ignores non-strings", %{schema: schema} do
      data = 100
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
