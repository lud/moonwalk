# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule Elixir.Moonwalk.Generated.Draft7.PropertyNamesTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/propertyNames.json
  """

  describe "propertyNames validation:" do
    setup do
      json_schema = %{"propertyNames" => %{"maxLength" => 3}}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all property names valid", c do
      data = %{"f" => %{}, "foo" => %{}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "some property names invalid", c do
      data = %{"foo" => %{}, "foobar" => %{}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object without properties is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = [1, 2, 3, 4]
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores strings", c do
      data = "foobar"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores other non-objects", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "propertyNames validation with pattern:" do
    setup do
      json_schema = %{"propertyNames" => %{"pattern" => "^a+$"}}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "matching property names valid", c do
      data = %{"a" => %{}, "aa" => %{}, "aaa" => %{}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "non-matching property name is invalid", c do
      data = %{"aaA" => %{}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "object without properties is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "propertyNames with boolean schema true:" do
    setup do
      json_schema = %{"propertyNames" => true}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with any properties is valid", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "empty object is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "propertyNames with boolean schema false:" do
    setup do
      json_schema = %{"propertyNames" => false}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "object with any properties is invalid", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "empty object is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
