defmodule Elixir.Moonwalk.Generated.Draft202012.ItemsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "a schema given for items" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"type" => "integer"}
      }

      {:ok, schema: schema}
    end

    test "valid items", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong type of items", %{schema: schema} do
      data = [1, "x"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ignores non-arrays", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "JavaScript pseudo-array is valid", %{schema: schema} do
      data = %{"0" => "invalid", "length" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items with boolean schema (true)" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "items" => true}
      {:ok, schema: schema}
    end

    test "any array is valid", %{schema: schema} do
      data = [1, "foo", true]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is valid", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items with boolean schema (false)" do
    setup do
      schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "items" => false}
      {:ok, schema: schema}
    end

    test "any non-empty array is invalid", %{schema: schema} do
      data = [1, "foo", true]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "empty array is valid", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items and subitems" do
    setup do
      schema = %{
        "$defs" => %{
          "item" => %{
            "items" => false,
            "prefixItems" => [
              %{"$ref" => "#/$defs/sub-item"},
              %{"$ref" => "#/$defs/sub-item"}
            ],
            "type" => "array"
          },
          "sub-item" => %{"required" => ["foo"], "type" => "object"}
        },
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => false,
        "prefixItems" => [
          %{"$ref" => "#/$defs/item"},
          %{"$ref" => "#/$defs/item"},
          %{"$ref" => "#/$defs/item"}
        ],
        "type" => "array"
      }

      {:ok, schema: schema}
    end

    test "valid items", %{schema: schema} do
      data = [
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too many items", %{schema: schema} do
      data = [
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "too many sub-items", %{schema: schema} do
      data = [
        [%{"foo" => nil}, %{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong item", %{schema: schema} do
      data = [
        %{"foo" => nil},
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong sub-item", %{schema: schema} do
      data = [
        [%{}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}],
        [%{"foo" => nil}, %{"foo" => nil}]
      ]

      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "fewer items is valid", %{schema: schema} do
      data = [[%{"foo" => nil}], [%{"foo" => nil}]]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nested items" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{
          "items" => %{
            "items" => %{"items" => %{"type" => "number"}, "type" => "array"},
            "type" => "array"
          },
          "type" => "array"
        },
        "type" => "array"
      }

      {:ok, schema: schema}
    end

    test "valid nested array", %{schema: schema} do
      data = [[[[1]], [[2], [3]]], [[[4], [5], [6]]]]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "nested array with invalid type", %{schema: schema} do
      data = [[[["1"]], [[2], [3]]], [[[4], [5], [6]]]]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "not deep enough", %{schema: schema} do
      data = [[[1], [2], [3]], [[4], [5], [6]]]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "prefixItems with no additional items allowed" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => false,
        "prefixItems" => [%{}, %{}, %{}]
      }

      {:ok, schema: schema}
    end

    test "empty array", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "fewer number of items present (1)", %{schema: schema} do
      data = [1]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "fewer number of items present (2)", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "equal number of items present", %{schema: schema} do
      data = [1, 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "additional items are not permitted", %{schema: schema} do
      data = [1, 2, 3, 4]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items does not look in applicators, valid case" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"prefixItems" => [%{"minimum" => 3}]}],
        "items" => %{"minimum" => 5}
      }

      {:ok, schema: schema}
    end

    test "prefixItems in allOf does not constrain items, invalid case", %{schema: schema} do
      data = [3, 5]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "prefixItems in allOf does not constrain items, valid case", %{schema: schema} do
      data = [5, 5]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "prefixItems validation adjusts the starting index for items" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"type" => "integer"},
        "prefixItems" => [%{"type" => "string"}]
      }

      {:ok, schema: schema}
    end

    test "valid items", %{schema: schema} do
      data = ["x", 2, 3]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "wrong type of second item", %{schema: schema} do
      data = ["x", "y"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items with heterogeneous array" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => false,
        "prefixItems" => [%{}]
      }

      {:ok, schema: schema}
    end

    test "heterogeneous invalid instance", %{schema: schema} do
      data = ["foo", "bar", 37]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid instance", %{schema: schema} do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "items with null instance elements" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"type" => "null"}
      }

      {:ok, schema: schema}
    end

    test "allows null elements", %{schema: schema} do
      data = [nil]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
