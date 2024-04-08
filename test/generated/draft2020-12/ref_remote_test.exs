defmodule Elixir.Moonwalk.Generated.Draft202012.RefRemoteTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/refRemote.json
  """

  describe "remote ref" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/integer.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "remote ref valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "remote ref invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "fragment within remote ref" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/subSchemas.json#/$defs/integer",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "remote fragment valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "remote fragment invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "anchor within remote ref" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/locationIndependentIdentifier.json#foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "remote anchor valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "remote anchor invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref within remote ref" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/subSchemas.json#/$defs/refToInteger",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "ref within ref valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ref within ref invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "base URI change" do
    setup do
      schema = %{
        "$id" => "http://localhost:1234/draft2020-12/",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{
          "$id" => "baseUriChange/",
          "items" => %{"$ref" => "folderInteger.json"}
        }
      }

      {:ok, schema: schema}
    end

    test "base URI change ref valid", %{schema: schema} do
      data = [[1]]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "base URI change ref invalid", %{schema: schema} do
      data = [["a"]]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "base URI change - change folder" do
    setup do
      schema = %{
        "$defs" => %{
          "baz" => %{
            "$id" => "baseUriChangeFolder/",
            "items" => %{"$ref" => "folderInteger.json"},
            "type" => "array"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/scope_change_defs1.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"list" => %{"$ref" => "baseUriChangeFolder/"}},
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = %{"list" => [1]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = %{"list" => ["a"]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "base URI change - change folder in subschema" do
    setup do
      schema = %{
        "$defs" => %{
          "baz" => %{
            "$defs" => %{
              "bar" => %{
                "items" => %{"$ref" => "folderInteger.json"},
                "type" => "array"
              }
            },
            "$id" => "baseUriChangeFolderInSubschema/"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/scope_change_defs2.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "list" => %{"$ref" => "baseUriChangeFolderInSubschema/#/$defs/bar"}
        },
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = %{"list" => [1]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = %{"list" => ["a"]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "root ref in remote ref" do
    setup do
      schema = %{
        "$id" => "http://localhost:1234/draft2020-12/object",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"name" => %{"$ref" => "name-defs.json#/$defs/orNull"}},
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "string is valid", %{schema: schema} do
      data = %{"name" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is valid", %{schema: schema} do
      data = %{"name" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is invalid", %{schema: schema} do
      data = %{"name" => %{"name" => nil}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "remote ref with ref to defs" do
    setup do
      schema = %{
        "$id" => "http://localhost:1234/draft2020-12/schema-remote-ref-ref-defs1.json",
        "$ref" => "ref-and-defs.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "invalid", %{schema: schema} do
      data = %{"bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid", %{schema: schema} do
      data = %{"bar" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "Location-independent identifier in remote ref" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/locationIndependentIdentifier.json#/$defs/refToInteger",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "integer is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "retrieved nested refs resolve relative to their URI not $id" do
    setup do
      schema = %{
        "$id" => "http://localhost:1234/draft2020-12/some-id",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"name" => %{"$ref" => "nested/foo-ref-string.json"}}
      }

      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = %{"name" => %{"foo" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is valid", %{schema: schema} do
      data = %{"name" => %{"foo" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "remote HTTP ref with different $id" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/different-id-ref-string.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "remote HTTP ref with different URN $id" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/urn-ref-string.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "remote HTTP ref with nested absolute ref" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/nested-absolute-ref-to-string.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "number is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$ref to $ref finds detached $anchor" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/detached-ref.json#/$defs/foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "non-number is invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
