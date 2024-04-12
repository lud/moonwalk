# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft202012.IdTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/id.json
  """

  describe "Invalid use of fragments in location-independent $id:" do
    setup do
      json_schema = %{
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Identifier name", c do
      data = %{
        "$defs" => %{"A" => %{"$id" => "#foo", "type" => "integer"}},
        "$ref" => "#foo"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier name and no ref", c do
      data = %{"$defs" => %{"A" => %{"$id" => "#foo"}}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier path", c do
      data = %{
        "$defs" => %{"A" => %{"$id" => "#/a/b", "type" => "integer"}},
        "$ref" => "#/a/b"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier name with absolute URI", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/bar#foo",
            "type" => "integer"
          }
        },
        "$ref" => "http://localhost:1234/draft2020-12/bar#foo"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier path with absolute URI", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/bar#/a/b",
            "type" => "integer"
          }
        },
        "$ref" => "http://localhost:1234/draft2020-12/bar#/a/b"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier name with base URI change in subschema", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$defs" => %{"B" => %{"$id" => "#foo", "type" => "integer"}},
            "$id" => "nested.json"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/root",
        "$ref" => "http://localhost:1234/draft2020-12/nested.json#foo"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier path with base URI change in subschema", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$defs" => %{"B" => %{"$id" => "#/a/b", "type" => "integer"}},
            "$id" => "nested.json"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/root",
        "$ref" => "http://localhost:1234/draft2020-12/nested.json#/a/b"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Valid use of empty fragments in location-independent $id:" do
    setup do
      json_schema = %{
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Identifier name with absolute URI", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/bar#",
            "type" => "integer"
          }
        },
        "$ref" => "http://localhost:1234/draft2020-12/bar"
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Identifier name with base URI change in subschema", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$defs" => %{"B" => %{"$id" => "#", "type" => "integer"}},
            "$id" => "nested.json"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/root",
        "$ref" => "http://localhost:1234/draft2020-12/nested.json#/$defs/B"
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "Unnormalized $ids are allowed but discouraged:" do
    setup do
      json_schema = %{
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Unnormalized identifier", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/foo/bar/../baz",
            "type" => "integer"
          }
        },
        "$ref" => "http://localhost:1234/draft2020-12/foo/baz"
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Unnormalized identifier and no ref", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/foo/bar/../baz",
            "type" => "integer"
          }
        }
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Unnormalized identifier with empty fragment", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/foo/bar/../baz#",
            "type" => "integer"
          }
        },
        "$ref" => "http://localhost:1234/draft2020-12/foo/baz"
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Unnormalized identifier with empty fragment and no ref", c do
      data = %{
        "$defs" => %{
          "A" => %{
            "$id" => "http://localhost:1234/draft2020-12/foo/bar/../baz#",
            "type" => "integer"
          }
        }
      }

      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
