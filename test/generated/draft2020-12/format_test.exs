defmodule Elixir.Moonwalk.Generated.Draft202012.FormatTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/format.json
  """

  describe "email format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "email"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid email string is only an annotation by default", %{schema: schema} do
      data = "2962"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "idn-email format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "idn-email"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid idn-email string is only an annotation by default", %{schema: schema} do
      data = "2962"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "regex format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "regex"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid regex string is only an annotation by default", %{schema: schema} do
      data = "^(abc]"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ipv4 format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "ipv4"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid ipv4 string is only an annotation by default", %{schema: schema} do
      data = "127.0.0.0.1"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ipv6 format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "ipv6"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid ipv6 string is only an annotation by default", %{schema: schema} do
      data = "12345::"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "idn-hostname format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "idn-hostname"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid idn-hostname string is only an annotation by default", %{schema: schema} do
      data = "〮실례.테스트"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "hostname format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "hostname"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid hostname string is only an annotation by default", %{schema: schema} do
      data = "-a-host-name-that-starts-with--"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "date format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "date"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid date string is only an annotation by default", %{schema: schema} do
      data = "06/19/1963"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "date-time format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "date-time"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid date-time string is only an annotation by default", %{schema: schema} do
      data = "1990-02-31T15:59:60.123-08:00"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "time format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "time"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid time string is only an annotation by default", %{schema: schema} do
      data = "08:30:06 PST"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "json-pointer format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "json-pointer"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid json-pointer string is only an annotation by default", %{schema: schema} do
      data = "/foo/bar~"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "relative-json-pointer format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "relative-json-pointer"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid relative-json-pointer string is only an annotation by default", %{schema: schema} do
      data = "/foo/bar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "iri format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "iri"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid iri string is only an annotation by default", %{schema: schema} do
      data = "http://2001:0db8:85a3:0000:0000:8a2e:0370:7334"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "iri-reference format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "iri-reference"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid iri-reference string is only an annotation by default", %{schema: schema} do
      data = "\\\\WINDOWS\\filëßåré"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "uri format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "uri"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid uri string is only an annotation by default", %{schema: schema} do
      data = "//foo.bar/?baz=qux#quux"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "uri-reference format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "uri-reference"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid uri-reference string is only an annotation by default", %{schema: schema} do
      data = "\\\\WINDOWS\\fileshare"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "uri-template format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "uri-template"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid uri-template string is only an annotation by default", %{schema: schema} do
      data = "http://example.com/dictionary/{term:1}/{term"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "uuid format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "uuid"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid uuid string is only an annotation by default", %{schema: schema} do
      data = "2eb8aa08-aa98-11ea-b4aa-73b441d1638"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "duration format ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "duration"
      }

      {:ok, schema: schema}
    end

    test "all string formats ignore integers", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore floats", %{schema: schema} do
      data = 13.7
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore objects", %{schema: schema} do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore arrays", %{schema: schema} do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore booleans", %{schema: schema} do
      data = false
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "all string formats ignore nulls", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid duration string is only an annotation by default", %{schema: schema} do
      data = "PT1D"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
