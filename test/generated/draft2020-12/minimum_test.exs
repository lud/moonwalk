# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft202012.MinimumTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/minimum.json
  """

  describe "minimum validation:" do
    setup do
      json_schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minimum" => 1.1}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "above the minimum is valid", c do
      data = 2.6
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "boundary point is valid", c do
      data = 1.1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "below the minimum is invalid", c do
      data = 0.6
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-numbers", c do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "minimum validation with signed integer:" do
    setup do
      json_schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "minimum" => -2}
      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "negative above the minimum is valid", c do
      data = -1
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "positive above the minimum is valid", c do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "boundary point is valid", c do
      data = -2
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "boundary point with float is valid", c do
      data = -2.0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "float below the minimum is invalid", c do
      data = -2.0001
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "int below the minimum is invalid", c do
      data = -3
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-numbers", c do
      data = "x"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
