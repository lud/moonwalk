defmodule Elixir.Moonwalk.Generated.Draft202012.PatternPropertiesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/patternProperties.json
  """

  describe "patternProperties validates properties matching a regex" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "patternProperties" => %{"f.*o" => %{"type" => "integer"}}
      }

      {:ok, schema: schema}
    end

    test "a single valid match is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "multiple valid matches is valid", %{schema: schema} do
      data = %{"foo" => 1, "foooooo" => 2}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a single invalid match is invalid", %{schema: schema} do
      data = %{"foo" => "bar", "fooooo" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "multiple invalid matches is invalid", %{schema: schema} do
      data = %{"foo" => "bar", "foooooo" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = ["foo"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores strings", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "multiple simultaneous patternProperties are validated" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "patternProperties" => %{
          "a*" => %{"type" => "integer"},
          "aaa*" => %{"maximum" => 20}
        }
      }

      {:ok, schema: schema}
    end

    test "a single valid match is valid", %{schema: schema} do
      data = %{"a" => 21}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a simultaneous match is valid", %{schema: schema} do
      data = %{"aaaa" => 18}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "multiple matches is valid", %{schema: schema} do
      data = %{"a" => 21, "aaaa" => 18}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an invalid due to one is invalid", %{schema: schema} do
      data = %{"a" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an invalid due to the other is invalid", %{schema: schema} do
      data = %{"aaaa" => 31}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an invalid due to both is invalid", %{schema: schema} do
      data = %{"aaa" => "foo", "aaaa" => 31}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "regexes are not anchored by default and are case sensitive" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "patternProperties" => %{
          "X_" => %{"type" => "string"},
          "[0-9]{2,}" => %{"type" => "boolean"}
        }
      }

      {:ok, schema: schema}
    end

    test "non recognized members are ignored", %{schema: schema} do
      data = %{"answer 1" => "42"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "recognized members are accounted for", %{schema: schema} do
      data = %{"a31b" => nil}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "regexes are case sensitive", %{schema: schema} do
      data = %{"a_x_3" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "regexes are case sensitive, 2", %{schema: schema} do
      data = %{"a_X_3" => 3}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "patternProperties with boolean schemas" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "patternProperties" => %{"b.*" => false, "f.*" => true}
      }

      {:ok, schema: schema}
    end

    test "object with property matching schema true is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with property matching schema false is invalid", %{schema: schema} do
      data = %{"bar" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with both properties is invalid", %{schema: schema} do
      data = %{"bar" => 2, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with a property matching both true and false is invalid", %{schema: schema} do
      data = %{"foobar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty object is valid", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "patternProperties with null valued instance properties" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "patternProperties" => %{"^.*bar$" => %{"type" => "null"}}
      }

      {:ok, schema: schema}
    end

    test "allows null values", %{schema: schema} do
      data = %{"foobar" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
