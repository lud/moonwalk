defmodule Moonwalk.Test.JsonSchemaSuite do
  alias Moonwalk.Schema.Validator
  use ExUnit.CaseTemplate
  @root_suites_dir Path.join([File.cwd!(), "deps", "json_schema_test_suite", "tests"])
  require Logger
  import ExUnit.Assertions

  def stream_cases(suite, config) do
    suite_dir = suite_dir!(suite)

    suite_dir
    |> Path.join("**/**.json")
    |> Path.wildcard()
    |> Stream.transform(
      fn -> [] end,
      fn path, discarded ->
        rel_path = Path.relative_to(path, suite_dir)

        case Map.fetch(config, rel_path) do
          {:ok, :unsupported} -> {[], []}
          {:ok, opts} -> {[%{path: path, rel_path: rel_path, opts: opts}], discarded}
          :error -> {[], [rel_path | discarded]}
        end
      end,
      &print_unchecked(suite, &1)
    )
    |> Stream.map(fn item ->
      %{path: path, opts: opts} = item

      Map.put(item, :test_cases, mashall_file(path, opts))
    end)
  end

  defp mashall_file(source_path, opts) do
    # If validate is false, all tests in the file are skipped
    validate = Keyword.get(opts, :validate, true)
    ignored = Keyword.get(opts, :ignore, [])

    source_path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn tcase ->
      %{"description" => tc_descr, "schema" => schema, "tests" => tests} = tcase
      tcase_ignored = tc_descr in ignored

      tests =
        Enum.map(tests, fn ttest ->
          %{"description" => tt_descr, "data" => data, "valid" => valid} = ttest
          ttest_ignored = tt_descr in ignored

          %{description: tt_descr, data: data, valid?: valid, skip?: ttest_ignored or tcase_ignored or not validate}
        end)

      %{description: tc_descr, schema: schema, tests: tests}
    end)
  end

  def suite_dir!(suite) do
    path = Path.join(@root_suites_dir, suite)

    case File.dir?(path) do
      true -> path
      false -> raise ArgumentError, "unknown suite #{suite}, could not find directory #{path}"
    end
  end

  def run_test(json_schema, schema, data, expected_valid) do
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

    case {expected_valid, valid?} do
      {true, true} ->
        :ok

      {false, false} ->
        test_error_format(validator)
        :ok

      _ ->
        flunk("""
        #{if expected_valid do
          "Expected valid, got errors"
        else
          "Expected errors, got valid"
        end}

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

  defp test_error_format(validator) do
    formatted = Validator.format_errors(validator)
    assert is_list(formatted)

    Enum.each(formatted, fn err ->
      assert {:ok, message} = Map.fetch(err, :message)
      assert is_binary(message)
    end)

    assert {:ok, _} = Jason.encode(formatted)
    # IO.puts(Jason.encode!(formatted, pretty: true))
  end

  def build_schema(json_schema, build_opts) do
    case Moonwalk.Schema.build(json_schema, [resolver: Moonwalk.Test.TestResolver] ++ build_opts) do
      {:ok, schema} -> schema
      {:error, reason} -> flunk(denorm_failure(json_schema, reason, []))
    end
  rescue
    e in FunctionClauseError ->
      IO.puts(denorm_failure(json_schema, e, __STACKTRACE__))
      reraise e, __STACKTRACE__
  end

  defp denorm_failure(json_schema, reason, stacktrace) do
    """
    Failed to denormalize schema.

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

  defp print_unchecked(suite, []) do
    IO.puts("All cases checked out for #{suite}")
  end

  defp print_unchecked(suite, paths) do
    total = length(paths)
    maxprint = 20
    more? = total > maxprint

    print_list =
      paths
      |> Enum.sort_by(fn
        "optional/format/" <> _ = rel_path -> {2, rel_path}
        "optional/" <> _ = rel_path -> {1, rel_path}
        rel_path -> {0, rel_path}
      end)
      |> Enum.take(maxprint)
      |> Enum.map_intersperse(?\n, fn filename -> "{#{inspect(filename)}, []}" end)

    """
    Unchecked test cases in #{suite}:
    #{print_list}
    #{(more? && "... (#{total - maxprint} more)") || ""}
    """
    |> IO.warn([])
  end
end
