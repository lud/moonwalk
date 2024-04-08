defmodule Moonwalk.SchemaValidationTest do
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduletag :json_schema

  # Each json schema "test suite" defined a series of test cases with a schema
  # and an array of "unit tests".

  {:ok, agent} = JsonSchemaSuite.load_dir_no_link("draft2020-12")
  # {:ok, agent} = JsonSchemaSuite.load_dir("latest")

  ignored = [
    # "contains.json",
    "format.json"
  ]

  Enum.each(ignored, fn
    {filename, _} -> JsonSchemaSuite.checkout_suite(agent, filename)
    filename -> JsonSchemaSuite.checkout_suite(agent, filename)
  end)

  suites = [
    {"minContains.json", []},
    {"maxContains.json", []},
    {"uniqueItems.json", []},
    {"dependentRequired.json", []},
    {"dependentSchemas.json", []},
    {"contains.json", []},
    {"additionalProperties.json", []},
    {"allOf.json", []},
    {"anchor.json", []},
    {"anyOf.json", []},
    {"boolean_schema.json", []},
    {"const.json", []},
    {"content.json", validate: false},
    {"default.json", []},
    {"defs.json", []},
    {"dynamicRef.json", [ignore: ["strict-tree schema, guards against misspelled properties"]]},
    {"enum.json", []},
    {"exclusiveMaximum.json", []},
    {"exclusiveMinimum.json", []},
    {"id.json", []},
    {"if-then-else.json", []},
    {"infinite-loop-detection.json", []},
    {"items.json", [ignore: ["JavaScript pseudo-array is valid"]]},
    {"maximum.json", []},
    {"maxItems.json", []},
    {"maxLength.json", []},
    {"minLength.json", []},
    {"minimum.json", []},
    {"minItems.json", []},
    {"multipleOf.json", []},
    {"oneOf.json", []},
    {"patternProperties.json", []},
    {"pattern.json", []},
    {"prefixItems.json", []},
    {"properties.json", []},
    {"ref.json", ignore: ["ref creates new scope when adjacent to keywords"]},
    {"refRemote.json", []},
    {"required.json", []},
    {"type.json", []},
    {"vocabulary.json", []}

    # Optionals

    # {"optional/anchor.json", []}

    # This one will require to get all supported keywords from loaded
    # vocabularies, for each document/scope, and check if a keyword is matched.
    # This may be done simply from the leftovers.
    #
    # {"optional/unknownKeyword.json", []}
  ]

  Enum.each(suites, fn {filename, opts} ->
    suite = JsonSchemaSuite.checkout_suite(agent, filename)
    validate? = Keyword.get(opts, :validate, true)
    ignored = Keyword.get(opts, :ignore, [])

    for test_case <- suite do
      %{"description" => case_descr, "tests" => tests} = test_case

      ignore_all? = case_descr in ignored

      describe "[#{filename}] #{case_descr}:" do
        setup do
          {:ok, %{test_case: unquote(Macro.escape(test_case))}}
        end

        @tag skip: ignore_all? or not validate?
        test "schema denormalization", %{test_case: test_case} do
          # debug_infinite_loop()
          build_schema(Map.fetch!(test_case, "schema"), test_case["description"])
        end

        for %{"description" => test_descr} = unit_test <- tests do
          @tag skip: ignore_all? or test_descr in ignored or not validate?
          test test_descr, %{test_case: test_case} do
            # debug_infinite_loop()
            unit_test = unquote(Macro.escape(unit_test))
            validation_test(test_case, unit_test)
          end
        end
      end
    end
  end)

  defp build_schema(json_schema, description) do
    case Moonwalk.Schema.build(json_schema, resolver: Moonwalk.Test.TestResolver) do
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

    schema = build_schema(json_schema, case_descr)

    {valid?, %Validator{} = validator} =
      case Moonwalk.Schema.validation_entrypoint(data, schema) do
        {:ok, casted, vdr} ->
          # This may fail if we have casting during the validation.
          assert data == casted
          {true, vdr}

        {:error, validator} ->
          {false, validator}
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

        DATA
        #{inspect(data, pretty: true)}

        SCHEMA
        #{inspect(schema, pretty: true)}

        ERRORS
        #{inspect(validator.errors, pretty: true)}
        """)
    end
  end

  setup_all do
    on_exit(fn -> JsonSchemaSuite.stop_warn_unchecked(unquote(agent)) end)
  end

  def debug_infinite_loop do
    parent = self()

    spawn_link(fn ->
      ref = Process.monitor(parent)
      debug_infinite_loop_loop(ref, parent, nil)
    end)
  end

  defp debug_infinite_loop_loop(ref, parent, prev) do
    {:current_function, cf} = Process.info(parent, :current_function)
    {:current_stacktrace, st} = Process.info(parent, :current_stacktrace)

    if prev != cf do
      IO.puts("current function: #{inspect(cf)}")
      Exception.format_stacktrace(st) |> IO.puts()
    end

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    after
      100 -> debug_infinite_loop_loop(ref, parent, cf)
    end
  end
end
