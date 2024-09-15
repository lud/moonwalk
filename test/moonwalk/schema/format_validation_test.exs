defmodule Moonwalk.Schema.FormatValidationTest do
  alias Moonwalk.Schema
  use ExUnit.Case, async: true

  defp build_schema(json_schema, opts \\ []) do
    Moonwalk.Schema.build(json_schema, [resolver: Moonwalk.Test.TestResolver] ++ opts)
  end

  defp raw_for(format) do
    %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "format" => format
    }
  end

  defp format_schema(format) do
    raw = raw_for(format)
    assert {:ok, schema} = build_schema(raw, formats: true)
    schema
  end

  @bad_ipv4 "not an ipv4"

  describe "build-time opt-in format validation" do
    # The default meta schema uses format-annotation and thus does not validate
    # formats
    setup do
      json_schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "ipv4"
      }

      {:ok, json_schema: json_schema}
    end

    test "default to no validation", ctx do
      assert {:ok, schema} = build_schema(ctx.json_schema)
      assert {:ok, @bad_ipv4} = Schema.validate(schema, @bad_ipv4)
    end

    test "validation can be enabled in build", ctx do
      # Note that passing `true` is the same as passing a list with a single
      # item, the default formats module
      assert {:ok, schema} = build_schema(ctx.json_schema, formats: true)
      assert {:error, {:schema_validation, [_]}} = Schema.validate(schema, @bad_ipv4)
    end
  end

  describe "build-time opt-out format validation" do
    # We use a custom schema that uses format-assertion by default
    setup do
      json_schema =
        %{
          "$schema" => "http://localhost:1234/draft2020-12/format-assertion-true.json",
          "format" => "ipv4"
        }

      {:ok, json_schema: json_schema}
    end

    test "default to no validation", ctx do
      assert {:ok, schema} = build_schema(ctx.json_schema)
      assert {:error, {:schema_validation, [_]}} = Schema.validate(schema, @bad_ipv4)
    end

    test "validation can be enabled in build", ctx do
      assert {:ok, schema} = build_schema(ctx.json_schema, formats: false)
      assert {:ok, @bad_ipv4} = Schema.validate(schema, @bad_ipv4)
    end
  end

  describe "custom formats module" do
    defmodule CustomFormat do
      @behaviour Moonwalk.Schema.FormatValidator

      @impl true
      def supported_formats do
        ["beam-language", "date"]
      end

      @impl true
      def validate_cast("beam-language", data) do
        if data in ["Elixir", "Erlang", "Gleam", "LFE"] do
          {:ok, data}
        else
          {:error, :non_beam_language}
        end
      end

      def validate_cast("date", anything) do
        {:ok, anything}
      end
    end

    test "passing a custom module" do
      # This will only support our formats
      formats = [CustomFormat]

      # We can validate the supported formats
      assert {:ok, schema} = build_schema(raw_for("beam-language"), formats: formats)
      assert {:ok, "LFE"} = Schema.validate(schema, "LFE")

      # but it does not support ipv4 format
      assert {:error, {:unsupported_format, "ipv4"}} = build_schema(raw_for("ipv4"), formats: formats)
    end

    test "adding a custom module over default one" do
      # Now if we ADD the module to the default we can support both formats
      formats = [CustomFormat | Moonwalk.Schema.default_format_validator_modules()]

      # We can validate the supported formats
      assert {:ok, schema} = build_schema(raw_for("beam-language"), formats: formats)
      assert {:ok, "LFE"} = Schema.validate(schema, "LFE")

      # and it does support ipv4 format
      assert {:ok, schema} = build_schema(raw_for("ipv4"), formats: formats)
      assert {:ok, "127.0.0.1"} = Schema.validate(schema, "127.0.0.1")

      # and we were able to override default implementations
      assert {:ok, schema} = build_schema(raw_for("date"), formats: formats)
      assert {:ok, "a long time ago"} = Schema.validate(schema, "a long time ago")
    end
  end

  describe "common formats" do
    defp run_cases(format, cases) do
      schema = format_schema(format)

      Enum.each(cases, fn {value, expected_valid?} ->
        case Schema.validate(schema, value) do
          {:ok, ^value} when expected_valid? ->
            :ok

          {:ok, ^value} when not expected_valid? ->
            flunk("""
            Expected value #{inspect(value)} to not be valid against format #{inspect(format)}.
            """)

          {:error, _} when not expected_valid? ->
            :ok

          {:error, _} when expected_valid? ->
            flunk("""
            Expected value #{inspect(value)} to be valid against format #{inspect(format)}.
            """)
        end
      end)
    end

    test "email" do
      from_block = fn valid?, block ->
        block
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(&{&1, valid?})
      end

      valid_emails =
        from_block.(true, ~S"""
        email@example.com
        firstname.lastname@example.com
        email@subdomain.example.com
        firstname+lastname@example.com
        email@123.123.123.123
        "email"@example.com
        1234567890@example.com
        email@example-one.com
        _______@example.com
        email@example.name
        email@example.museum
        email@example.co.jp
        firstname-lastname@example.com
        """)

      invalid_emails =
        from_block.(false, ~S"""
        plainaddress
        #@%^%#$@#$@#.com
        @example.com
        Joe Smith <email@example.com>
        email.example.com
        email@example@example.com
        .email@example.com
        email.@example.com
        email..email@example.com
        あいうえお@example.com
        email@example.com (Joe Smith)
        email@-example.com
        email@example..com
        Abc..123@example.com
        ”(),:;<>[\]@example.com
        just”not”right@example.com
        this\ is"really"not\allowed@example.com
        """)

      run_cases("email", valid_emails)
      run_cases("email", invalid_emails)
    end
  end
end
