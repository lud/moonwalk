defmodule Moonwalk.SchemaValidationTest do
  alias Moonwalk.Test.JsonSchemaTestSuite
  use ExUnit.Case, async: true

  @moduletag :json_schema

  # Each json schema "test suite" defined a series of test cases with a schema
  # and an array of "unit tests".

  {:ok, agent} = JsonSchemaTestSuite.load_dir("draft2020-12")
  # {:ok, agent} = JsonSchemaTestSuite.load_dir("latest")

  ignored = [
    # "contains.json",
    "format.json"
  ]

  Enum.each(ignored, fn filename -> JsonSchemaTestSuite.checkout_suite(agent, filename) end)

  suites = [
    # {"id.json", []},
    # {"anchor.json", []},
    # {"defs.json", []},
    {"infinite-loop-detection.json", []},
    {"items.json", [ignore: ["JavaScript pseudo-array is valid"]]},
    {"exclusiveMaximum.json", []},
    {"exclusiveMinimum.json", []},
    {"boolean_schema.json", []},
    {"enum.json", []},
    {"anyOf.json", []},
    {"oneOf.json", []},
    {"allOf.json", []},
    {"const.json", []},
    {"properties.json", []},
    {"minimum.json", []},
    {"maximum.json", []},
    {"type.json", []},
    {"content.json", validate: false}
  ]

  Enum.each(suites, fn {filename, opts} ->
    suite = JsonSchemaTestSuite.checkout_suite(agent, filename)
    validate? = Keyword.get(opts, :validate, true)
    ignored = Keyword.get(opts, :ignore, [])

    for test_case <- suite do
      %{"description" => case_descr, "tests" => tests} = test_case

      describe filename <> " - " <> case_descr <> " - " do
        setup do
          {:ok, %{test_case: unquote(Macro.escape(test_case))}}
        end

        # If we are not testing the validation we must at least ensure that
        # the schema can be manipulated by the library

        test "schema denormalization", %{test_case: test_case} do
          denorm_schema(Map.fetch!(test_case, "schema"), test_case["description"])
        end

        if validate? do
          for %{"description" => test_descr} = unit_test <- tests, test_descr not in ignored do
            test test_descr, %{test_case: test_case} do
              unit_test = unquote(Macro.escape(unit_test))
              validation_test(test_case, unit_test)
            end
          end
        end
      end
    end
  end)

  def resolve_well_known(url) do
    file =
      case url do
        "https://json-schema.org/draft/2020-12/schema" -> "draft-2020-12.schema.json"
      end

    path = Path.join([:code.priv_dir(:moonwalk), "schemas", file])
    json = File.read!(path)
    Jason.decode(json)
  end

  defp denorm_schema(json_schema, description) do
    case Moonwalk.Schema.denormalize(json_schema, resolver: {__MODULE__, :resolve_well_known, []}) do
      {:ok, schema} -> schema
      {:error, reason} -> flunk(denorm_failure(json_schema, reason, [], description))
    end
  rescue
    e in FunctionClauseError ->
      IO.puts(denorm_failure(json_schema, e, __STACKTRACE__, description))
      reraise e, __STACKTRACE__
  end

  defp denorm_failure(json_schema, reason, stacktrace, description) do
    """
    Failed to denormalize schema: #{description}

    SCHEMA
    #{inspect(json_schema, pretty: true)}

    ERROR
    #{if is_exception(reason) do
      Exception.format(:error, reason, stacktrace)
    else
      inspect(reason, pretty: true)
    end}
    """
  end

  defp validation_test(test_case, unit_test) do
    %{"schema" => json_schema, "description" => case_descr} = test_case
    %{"data" => data, "valid" => expected_valid, "description" => test_descr} = unit_test

    schema = denorm_schema(json_schema, case_descr)

    {valid?, errors} =
      case Moonwalk.Schema.validate(data, schema) do
        {:ok, casted} ->
          # This may fail if we have casting during the validation.
          assert data == casted
          {true, nil}

        {:error, errors} ->
          {false, errors}
      end

    # assert the expected result

    case valid? do
      ^expected_valid ->
        :ok

      _ ->
        flunk("""
        #{if expected_valid do
          "Expected valid, got errors"
        else
          "Expected errors, got valid"
        end}

        CASE
        #{test_descr}

        JSON SCHEMA
        #{inspect(json_schema, pretty: true)}

        SCHEMA
        #{inspect(schema, pretty: true)}

        DATA
        #{inspect(data, pretty: true)}

        ERRORS
        #{inspect(errors, pretty: true)}
        """)
    end
  end

  JsonSchemaTestSuite.stop_warn_unchecked(agent)

  test "same layers" do
    assert Moonwalk.Schema.layer_of(:properties) ==
             Moonwalk.Schema.layer_of(:additional_properties)

    assert Moonwalk.Schema.layer_of(:properties) == Moonwalk.Schema.layer_of(:pattern_properties)
  end
end
