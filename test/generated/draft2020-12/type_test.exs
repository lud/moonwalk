defmodule Elixir.Moonwalk.Generated.Draft202012.TypeTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "integer type matches integers" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "integer"
      }

      {:ok, schema: schema}
    end

    test "an integer is an integer", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float with zero fractional part is an integer", %{schema: schema} do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is not an integer", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is not an integer", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is still not an integer, even if it looks like one", %{schema: schema} do
      data = "1"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is not an integer", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is not an integer", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a boolean is not an integer", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is not an integer", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "number type matches numbers" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "number"
      }

      {:ok, schema: schema}
    end

    test "an integer is a number", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float with zero fractional part is a number (and an integer)", %{schema: schema} do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is a number", %{schema: schema} do
      data = 1.1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is not a number", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is still not a number, even if it looks like one", %{schema: schema} do
      data = "1"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is not a number", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is not a number", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a boolean is not a number", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is not a number", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "string type matches strings" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "string"
      }

      {:ok, schema: schema}
    end

    test "1 is not a string", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is not a string", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is a string", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is still a string, even if it looks like a number", %{schema: schema} do
      data = "1"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an empty string is still a string", %{schema: schema} do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is not a string", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is not a string", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a boolean is not a string", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is not a string", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "object type matches objects" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "an integer is not an object", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is not an object", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is not an object", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is an object", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is not an object", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a boolean is not an object", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is not an object", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "array type matches arrays" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "array"
      }

      {:ok, schema: schema}
    end

    test "an integer is not an array", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is not an array", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is not an array", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is not an array", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is an array", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a boolean is not an array", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is not an array", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "boolean type matches booleans" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "boolean"
      }

      {:ok, schema: schema}
    end

    test "an integer is not a boolean", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "zero is not a boolean", %{schema: schema} do
      data = 0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is not a boolean", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is not a boolean", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an empty string is not a boolean", %{schema: schema} do
      data = ""
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is not a boolean", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is not a boolean", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "true is a boolean", %{schema: schema} do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "false is a boolean", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is not a boolean", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "null type matches only the null object" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "type" => "null"}
      {:ok, schema: schema}
    end

    test "an integer is not null", %{schema: schema} do
      data = 1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is not null", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "zero is not null", %{schema: schema} do
      data = 0
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is not null", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an empty string is not null", %{schema: schema} do
      data = ""
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is not null", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is not null", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "true is not null", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "false is not null", %{schema: schema} do
      data = false
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is null", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "multiple types can be specified in an array" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => ["integer", "string"]
      }

      {:ok, schema: schema}
    end

    test "an integer is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a float is invalid", %{schema: schema} do
      data = 1.1
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an object is invalid", %{schema: schema} do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an array is invalid", %{schema: schema} do
      data = []
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a boolean is invalid", %{schema: schema} do
      data = true
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is invalid", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "type as array with one item" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => ["string"]
      }

      {:ok, schema: schema}
    end

    test "string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number is invalid", %{schema: schema} do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "type: array or object" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => ["array", "object"]
      }

      {:ok, schema: schema}
    end

    test "array is valid", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is valid", %{schema: schema} do
      data = %{"foo" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number is invalid", %{schema: schema} do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is invalid", %{schema: schema} do
      data = nil
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "type: array, object or null" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => ["array", "object", "null"]
      }

      {:ok, schema: schema}
    end

    test "array is valid", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object is valid", %{schema: schema} do
      data = %{"foo" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "null is valid", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number is invalid", %{schema: schema} do
      data = 123
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
