defmodule Elixir.Moonwalk.Generated.Draft202012.EnumTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/enum.json
  """

  describe "simple enum validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [1, 2, 3]
      }

      {:ok, schema: schema}
    end

    test "one of the enum is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "something else is invalid", %{schema: schema} do
      data = 4
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "heterogeneous enum validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [6, "foo", [], true, %{"foo" => 12}]
      }

      {:ok, schema: schema}
    end

    test "one of the enum is valid", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "something else is invalid", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "objects are deep compared", %{schema: schema} do
      data = %{"foo" => false}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid object matches", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "extra properties in object is invalid", %{schema: schema} do
      data = %{"boo" => 42, "foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "heterogeneous enum-with-null validation ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [6, nil]
      }

      {:ok, schema: schema}
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number is valid", %{schema: schema} do
      data = 6
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "something else is invalid", %{schema: schema} do
      data = "test"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enums in properties ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "bar" => %{"enum" => ["bar"]},
          "foo" => %{"enum" => ["foo"]}
        },
        "required" => ["bar"],
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "both properties are valid", %{schema: schema} do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong foo value", %{schema: schema} do
      data = %{"bar" => "bar", "foo" => "foot"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong bar value", %{schema: schema} do
      data = %{"bar" => "bart", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing optional property is valid", %{schema: schema} do
      data = %{"bar" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing required property is invalid", %{schema: schema} do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "missing all properties is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with escaped characters ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => ["foo\nbar", "foo\rbar"]
      }

      {:ok, schema: schema}
    end

    test "member 1 is valid", %{schema: schema} do
      data = "foo\nbar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "member 2 is valid", %{schema: schema} do
      data = "foo\rbar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "another string is invalid", %{schema: schema} do
      data = "abc"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with false does not match 0 ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [false]
      }

      {:ok, schema: schema}
    end

    test "false is valid", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "integer zero is invalid", %{schema: schema} do
      data = 0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float zero is invalid", %{schema: schema} do
      data = 0.0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with [false] does not match [0] ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [[false]]
      }

      {:ok, schema: schema}
    end

    test "[false] is valid", %{schema: schema} do
      data = [false]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[0] is invalid", %{schema: schema} do
      data = [0]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[0.0] is invalid", %{schema: schema} do
      data = [0.0]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with true does not match 1 ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "enum" => [true]}
      {:ok, schema: schema}
    end

    test "true is valid", %{schema: schema} do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "integer one is invalid", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float one is invalid", %{schema: schema} do
      data = 1.0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with [true] does not match [1] ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [[true]]
      }

      {:ok, schema: schema}
    end

    test "[true] is valid", %{schema: schema} do
      data = [true]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[1] is invalid", %{schema: schema} do
      data = [1]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[1.0] is invalid", %{schema: schema} do
      data = [1.0]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with 0 does not match false ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "enum" => [0]}
      {:ok, schema: schema}
    end

    test "false is invalid", %{schema: schema} do
      data = false
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "integer zero is valid", %{schema: schema} do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float zero is valid", %{schema: schema} do
      data = 0.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with [0] does not match [false] ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "enum" => [[0]]}
      {:ok, schema: schema}
    end

    test "[false] is invalid", %{schema: schema} do
      data = [false]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[0] is valid", %{schema: schema} do
      data = [0]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[0.0] is valid", %{schema: schema} do
      data = [0.0]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with 1 does not match true ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "enum" => [1]}
      {:ok, schema: schema}
    end

    test "true is invalid", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "integer one is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float one is valid", %{schema: schema} do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "enum with [1] does not match [true] ⋅" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "enum" => [[1]]}
      {:ok, schema: schema}
    end

    test "[true] is invalid", %{schema: schema} do
      data = [true]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[1] is valid", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "[1.0] is valid", %{schema: schema} do
      data = [1.0]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nul characters in strings ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [<<104, 101, 108, 108, 111, 0, 116, 104, 101, 114, 101>>]
      }

      {:ok, schema: schema}
    end

    test "match string with nul", %{schema: schema} do
      data = <<104, 101, 108, 108, 111, 0, 116, 104, 101, 114, 101>>
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "do not match string lacking nul", %{schema: schema} do
      data = "hellothere"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
