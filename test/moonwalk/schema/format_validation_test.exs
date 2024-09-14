defmodule Moonwalk.Schema.FormatValidationTest do
  alias Moonwalk.Schema
  use ExUnit.Case, async: true

  defp build_schema(json_schema, opts \\ []) do
    assert {:ok, schema} = Moonwalk.Schema.build(json_schema, [resolver: Moonwalk.Test.TestResolver] ++ opts)
    schema |> dbg()
  end

  @bad_ipv4 "not an ipv4"

  describe "build-time opt-in format validation" do
    # The default meta schema uses format-annotation and thus does not validate
    # formats
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "format": "ipv4"
        }
        """)

      {:ok, json_schema: json_schema}
    end

    test "default to no validation", ctx do
      schema = build_schema(ctx.json_schema)
      assert {:ok, @bad_ipv4} = Schema.validate(schema, @bad_ipv4)
    end

    test "validation can be enabled in build", ctx do
      schema = build_schema(ctx.json_schema, formats: true)
      assert {:error, {:schema_validation, [_]}} = Schema.validate(schema, @bad_ipv4)
    end
  end

  describe "build-time opt-out format validation" do
    # We use a custom schema that uses format-assertion by default
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "http://localhost:1234/draft2020-12/format-assertion-true.json",
          "format": "ipv4"
        }
        """)

      {:ok, json_schema: json_schema}
    end

    test "default to no validation", ctx do
      schema = build_schema(ctx.json_schema)
      assert {:error, {:schema_validation, [_]}} = Schema.validate(schema, @bad_ipv4)
    end

    test "validation can be enabled in build", ctx do
      schema = build_schema(ctx.json_schema, formats: false)
      assert {:ok, @bad_ipv4} = Schema.validate(schema, @bad_ipv4)
    end
  end
end
