defmodule Elixir.Moonwalk.Generated.Draft202012.PropertiesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/properties.json
  """

  describe "object properties validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "bar" => %{"type" => "string"},
          "foo" => %{"type" => "integer"}
        }
      }

      {:ok, schema: schema}
    end

    test "both properties present and valid is valid", %{schema: schema} do
      data = %{"bar" => "baz", "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "one property invalid is invalid", %{schema: schema} do
      data = %{"bar" => %{}, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both properties invalid is invalid", %{schema: schema} do
      data = %{"bar" => %{}, "foo" => []}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "doesn't invalidate other properties", %{schema: schema} do
      data = %{"quux" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "properties, patternProperties, additionalProperties interaction ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => %{"type" => "integer"},
        "patternProperties" => %{"f.o" => %{"minItems" => 2}},
        "properties" => %{
          "bar" => %{"type" => "array"},
          "foo" => %{"maxItems" => 3, "type" => "array"}
        }
      }

      {:ok, schema: schema}
    end

    test "property validates property", %{schema: schema} do
      data = %{"foo" => [1, 2]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "property invalidates property", %{schema: schema} do
      data = %{"foo" => [1, 2, 3, 4]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "patternProperty invalidates property", %{schema: schema} do
      data = %{"foo" => []}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "patternProperty validates nonproperty", %{schema: schema} do
      data = %{"fxo" => [1, 2]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "patternProperty invalidates nonproperty", %{schema: schema} do
      data = %{"fxo" => []}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "additionalProperty ignores property", %{schema: schema} do
      data = %{"bar" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "additionalProperty validates others", %{schema: schema} do
      data = %{"quux" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "additionalProperty invalidates others", %{schema: schema} do
      data = %{"quux" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "properties with boolean schema ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"bar" => false, "foo" => true}
      }

      {:ok, schema: schema}
    end

    test "no property present is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "only 'true' property present is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "only 'false' property present is invalid", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "both properties present is invalid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "properties with escaped characters ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "foo\tbar" => %{"type" => "number"},
          "foo\nbar" => %{"type" => "number"},
          "foo\fbar" => %{"type" => "number"},
          "foo\rbar" => %{"type" => "number"},
          "foo\"bar" => %{"type" => "number"},
          "foo\\bar" => %{"type" => "number"}
        }
      }

      {:ok, schema: schema}
    end

    test "object with all numbers is valid", %{schema: schema} do
      data = %{
        "foo\tbar" => 1,
        "foo\nbar" => 1,
        "foo\fbar" => 1,
        "foo\rbar" => 1,
        "foo\"bar" => 1,
        "foo\\bar" => 1
      }

      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with strings is invalid", %{schema: schema} do
      data = %{
        "foo\tbar" => "1",
        "foo\nbar" => "1",
        "foo\fbar" => "1",
        "foo\rbar" => "1",
        "foo\"bar" => "1",
        "foo\\bar" => "1"
      }

      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "properties with null valued instance properties ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"type" => "null"}}
      }

      {:ok, schema: schema}
    end

    test "allows null values", %{schema: schema} do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "properties whose names are Javascript object property names ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "__proto__" => %{"type" => "number"},
          "constructor" => %{"type" => "number"},
          "toString" => %{"properties" => %{"length" => %{"type" => "string"}}}
        }
      }

      {:ok, schema: schema}
    end

    test "ignores arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "none of the properties mentioned", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "__proto__ not valid", %{schema: schema} do
      data = %{"__proto__" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "toString not valid", %{schema: schema} do
      data = %{"toString" => %{"length" => 37}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "constructor not valid", %{schema: schema} do
      data = %{"constructor" => %{"length" => 37}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all present and valid", %{schema: schema} do
      data = %{"__proto__" => 12, "constructor" => 37, "toString" => %{"length" => "foo"}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
