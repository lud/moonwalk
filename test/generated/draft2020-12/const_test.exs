defmodule Elixir.Moonwalk.Generated.Draft202012.ConstTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/const.json
  """

  describe "const validation" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => 2}
      {:ok, schema: schema}
    end

    test "same value is valid", %{schema: schema} do
      data = 2
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "another value is invalid", %{schema: schema} do
      data = 5
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "another type is invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with object" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => %{"baz" => "bax", "foo" => "bar"}
      }

      {:ok, schema: schema}
    end

    test "same object is valid", %{schema: schema} do
      data = %{"baz" => "bax", "foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "same object with different property order is valid", %{schema: schema} do
      data = %{"baz" => "bax", "foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "another object is invalid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "another type is invalid", %{schema: schema} do
      data = [1, 2]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with array" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => [%{"foo" => "bar"}]
      }

      {:ok, schema: schema}
    end

    test "same array is valid", %{schema: schema} do
      data = [%{"foo" => "bar"}]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "another array item is invalid", %{schema: schema} do
      data = [2]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "array with additional items is invalid", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with null" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => nil}
      {:ok, schema: schema}
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "not null is invalid", %{schema: schema} do
      data = 0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with false does not match 0" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => false}
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

  describe "const with true does not match 1" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => true}
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

  describe "const with [false] does not match [0]" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => [false]
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

  describe "const with [true] does not match [1]" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => [true]
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

  describe "const with {\"a\": false} does not match {\"a\": 0}" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => %{"a" => false}
      }

      {:ok, schema: schema}
    end

    test "{\"a\": false} is valid", %{schema: schema} do
      data = %{"a" => false}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "{\"a\": 0} is invalid", %{schema: schema} do
      data = %{"a" => 0}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "{\"a\": 0.0} is invalid", %{schema: schema} do
      data = %{"a" => 0.0}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with {\"a\": true} does not match {\"a\": 1}" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => %{"a" => true}
      }

      {:ok, schema: schema}
    end

    test "{\"a\": true} is valid", %{schema: schema} do
      data = %{"a" => true}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "{\"a\": 1} is invalid", %{schema: schema} do
      data = %{"a" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "{\"a\": 1.0} is invalid", %{schema: schema} do
      data = %{"a" => 1.0}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with 0 does not match other zero-like types" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => 0}
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

    test "empty object is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty string is invalid", %{schema: schema} do
      data = ""
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "const with 1 does not match true" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => 1}
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

  describe "const with -2.0 matches integer and float types" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "const" => -2.0}
      {:ok, schema: schema}
    end

    test "integer -2 is valid", %{schema: schema} do
      data = -2
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "integer 2 is invalid", %{schema: schema} do
      data = 2
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float -2.0 is valid", %{schema: schema} do
      data = -2.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float 2.0 is invalid", %{schema: schema} do
      data = 2.0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float -2.00001 is invalid", %{schema: schema} do
      data = -2.00001
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "float and integers are equal up to 64-bit representation limits" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => 9_007_199_254_740_992
      }

      {:ok, schema: schema}
    end

    test "integer is valid", %{schema: schema} do
      data = 9_007_199_254_740_992
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "integer minus one is invalid", %{schema: schema} do
      data = 9_007_199_254_740_991
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float is valid", %{schema: schema} do
      data = 9_007_199_254_740_992.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "float minus one is invalid", %{schema: schema} do
      data = 9_007_199_254_740_991.0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nul characters in strings" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "const" => <<104, 101, 108, 108, 111, 0, 116, 104, 101, 114, 101>>
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
