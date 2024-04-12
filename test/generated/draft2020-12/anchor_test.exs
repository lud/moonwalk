# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft202012.AnchorTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/anchor.json
  """

  describe "Location-independent identifier:" do
    setup do
      json_schema = %{
        "$defs" => %{"A" => %{"$anchor" => "foo", "type" => "integer"}},
        "$ref" => "#foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Location-independent identifier with absolute URI:" do
    setup do
      json_schema = %{
        "$defs" => %{
          "A" => %{
            "$anchor" => "foo",
            "$id" => "http://localhost:1234/draft2020-12/bar",
            "type" => "integer"
          }
        },
        "$ref" => "http://localhost:1234/draft2020-12/bar#foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Location-independent identifier with base URI change in subschema:" do
    setup do
      json_schema = %{
        "$defs" => %{
          "A" => %{
            "$defs" => %{"B" => %{"$anchor" => "foo", "type" => "integer"}},
            "$id" => "nested.json"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/root",
        "$ref" => "http://localhost:1234/draft2020-12/nested.json#foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "match", c do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "mismatch", c do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "same $anchor with different base uri:" do
    setup do
      json_schema = %{
        "$defs" => %{
          "A" => %{
            "$id" => "child1",
            "allOf" => [
              %{"$anchor" => "my_anchor", "$id" => "child2", "type" => "number"},
              %{"$anchor" => "my_anchor", "type" => "string"}
            ]
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/foobar",
        "$ref" => "child1#my_anchor",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "$ref resolves to /$defs/A/allOf/1", c do
      data = "a"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "$ref does not resolve to /$defs/A/allOf/0", c do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "invalid anchors:" do
    setup do
      json_schema = %{
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "MUST start with a letter (and not #)", c do
      data = %{"$anchor" => "#foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "JSON pointers are not valid", c do
      data = %{"$anchor" => "/a/b"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid with valid beginning", c do
      data = %{"$anchor" => "foo#something"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
