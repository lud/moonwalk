defmodule Elixir.Moonwalk.Generated.Draft202012.RequiredTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "required validation" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"bar" => %{}, "foo" => %{}},
        "required" => ["foo"]
      }

      {:ok, schema: schema}
    end

    test "present required property is valid", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "non-present required property is invalid", %{schema: schema} do
      data = %{"bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores strings", %{schema: schema} do
      data = ""
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores other non-objects", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "required default validation" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{}}
      }

      {:ok, schema: schema}
    end

    test "not required by default", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "required with empty array" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{}},
        "required" => []
      }

      {:ok, schema: schema}
    end

    test "property not required", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "required with escaped characters" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "required" => ["foo\nbar", "foo\"bar", "foo\\bar", "foo\rbar", "foo\tbar", "foo\fbar"]
      }

      {:ok, schema: schema}
    end

    test "object with all properties present is valid", %{schema: schema} do
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

    test "object with some properties missing is invalid", %{schema: schema} do
      data = %{"foo\nbar" => "1", "foo\"bar" => "1"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "required properties whose names are Javascript object property names" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "required" => ["__proto__", "toString", "constructor"]
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
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "__proto__ present", %{schema: schema} do
      data = %{"__proto__" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "toString present", %{schema: schema} do
      data = %{"toString" => %{"length" => 37}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "constructor present", %{schema: schema} do
      data = %{"constructor" => %{"length" => 37}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all present", %{schema: schema} do
      data = %{"__proto__" => 12, "constructor" => 37, "toString" => %{"length" => "foo"}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
