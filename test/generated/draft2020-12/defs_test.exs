defmodule Elixir.Moonwalk.Generated.Draft202012.DefsTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/defs.json
  """

  describe "validate definition against metaschema ⋅" do
    setup do
      schema = %{
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "valid definition schema", %{schema: schema} do
      data = %{"$defs" => %{"foo" => %{"type" => "integer"}}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid definition schema", %{schema: schema} do
      data = %{"$defs" => %{"foo" => %{"type" => 1}}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
