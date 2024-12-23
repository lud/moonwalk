# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule Elixir.Moonwalk.Generated.Draft202012.TimeTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/optional/format/time.json
  """

  describe "validation of time strings:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "format": "time"
        }
        """)

      schema =
        JsonSchemaSuite.build_schema(json_schema,
          default_draft: "https://json-schema.org/draft/2020-12/schema",
          formats: true
        )

      {:ok, json_schema: json_schema, schema: schema}
    end

    test "all string formats ignore integers", c do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore floats", c do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore objects", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore booleans", c do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all string formats ignore nulls", c do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid time string", c do
      data = "08:30:06Z"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid time string with extra leading zeros", c do
      data = "008:030:006Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid time string with no leading zero for single digit", c do
      data = "8:3:6Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "hour, minute, second must be two digits", c do
      data = "8:0030:6Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "a valid time string with leap second, Zulu", c do
      data = "23:59:60Z"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, Zulu (wrong hour)", c do
      data = "22:59:60Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, Zulu (wrong minute)", c do
      data = "23:58:60Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "valid leap second, zero time-offset", c do
      data = "23:59:60+00:00"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, zero time-offset (wrong hour)", c do
      data = "22:59:60+00:00"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, zero time-offset (wrong minute)", c do
      data = "23:58:60+00:00"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "valid leap second, positive time-offset", c do
      data = "01:29:60+01:30"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "valid leap second, large positive time-offset", c do
      data = "23:29:60+23:30"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, positive time-offset (wrong hour)", c do
      data = "23:59:60+01:00"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, positive time-offset (wrong minute)", c do
      data = "23:59:60+00:30"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "valid leap second, negative time-offset", c do
      data = "15:59:60-08:00"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "valid leap second, large negative time-offset", c do
      data = "00:29:60-23:30"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, negative time-offset (wrong hour)", c do
      data = "23:59:60-01:00"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid leap second, negative time-offset (wrong minute)", c do
      data = "23:59:60-00:30"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid time string with second fraction", c do
      data = "23:20:50.52Z"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid time string with precise second fraction", c do
      data = "08:30:06.283185Z"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid time string with plus offset", c do
      data = "08:30:06+00:20"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid time string with minus offset", c do
      data = "08:30:06-08:00"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "hour, minute in time-offset must be two digits", c do
      data = "08:30:06-8:000"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a valid time string with case-insensitive Z", c do
      data = "08:30:06z"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid hour", c do
      data = "24:00:00Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid minute", c do
      data = "00:60:00Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid second", c do
      data = "00:00:61Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid leap second (wrong hour)", c do
      data = "22:59:60Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid leap second (wrong minute)", c do
      data = "23:58:60Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid time numoffset hour", c do
      data = "01:02:03+24:00"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid time numoffset minute", c do
      data = "01:02:03+00:60"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid time string with invalid time with both Z and numoffset", c do
      data = "01:02:03Z+00:30"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "an invalid offset indicator", c do
      data = "08:30:06 PST"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "only RFC3339 not all of ISO 8601 are valid", c do
      data = "01:01:01,1111"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "no time offset", c do
      data = "12:00:00"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    @tag :skip
    test "no time offset with second fraction", c do
      data = "12:00:00.52"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid non-ASCII '২' (a Bengali 2)", c do
      data = "1২:00:00Z"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "offset not starting with plus or minus", c do
      data = "08:30:06#00:20"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "contains letters", c do
      data = "ab:cd:ef"
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
