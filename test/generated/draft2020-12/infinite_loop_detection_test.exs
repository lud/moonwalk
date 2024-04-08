defmodule Elixir.Moonwalk.Generated.Draft202012.InfiniteLoopDetectionTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "evaluating the same schema location against the same data location twice is not a sign of an infinite loop" do
    setup do
      schema = %{
        "$defs" => %{"int" => %{"type" => "integer"}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"properties" => %{"foo" => %{"$ref" => "#/$defs/int"}}},
          %{"additionalProperties" => %{"$ref" => "#/$defs/int"}}
        ]
      }

      {:ok, schema: schema}
    end

    test "passing case", %{schema: schema} do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "failing case", %{schema: schema} do
      data = %{"foo" => "a string"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
