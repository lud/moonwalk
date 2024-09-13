# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule Elixir.Moonwalk.Generated.Draft7.MultipleOfTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft7/multipleOf.json
  """

  describe "by int:" do
    setup do
      json_schema = %{"multipleOf" => 2}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "int by int", c do
      data = 10
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "int by int fail", c do
      data = 7
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores non-numbers", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "by number:" do
    setup do
      json_schema = %{"multipleOf" => 1.5}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "zero is multiple of anything", c do
      data = 0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "4.5 is multiple of 1.5", c do
      data = 4.5
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "35 is not multiple of 1.5", c do
      data = 35
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "by small number:" do
    setup do
      json_schema = %{"multipleOf" => 0.0001}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "0.0075 is multiple of 0.0001", c do
      data = 0.0075
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "0.00751 is not multiple of 0.0001", c do
      data = 0.00751
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "float division = inf:" do
    setup do
      json_schema = %{"multipleOf" => 0.123456789, "type" => "integer"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "always invalid, but naive implementations may raise an overflow error", c do
      data = 1.0e308
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "small multiple of large integer:" do
    setup do
      json_schema = %{"multipleOf" => 1.0e-8, "type" => "integer"}
      schema = JsonSchemaSuite.build_schema(json_schema, default_draft: "http://json-schema.org/draft-07/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "any integer is a multiple of 1e-8", c do
      data = 12_391_239_123
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
