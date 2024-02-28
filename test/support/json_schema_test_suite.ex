defmodule Moonwalk.Test.JsonSchemaTestSuite do
  use ExUnit.CaseTemplate
  @test_dir Path.join([File.cwd!(), "deps", "json_schema_test_suite", "tests"])
  require Logger

  def load_dir(suite_dir) do
    dir = Path.join(@test_dir, suite_dir)

    files =
      dir
      |> Path.join("**/*.json")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(fn path -> {Path.relative_to(path, dir), path, false} end)

    {:ok, _} = Agent.start_link(fn -> %{dir: dir, files: files} end, name: __MODULE__)
  end

  def checkout_suite(agent, subpath) do
    Agent.get_and_update(agent, fn state ->
      %{files: files} = state

      found =
        case List.keyfind(files, subpath, 0) do
          {^subpath, path, false} ->
            {:ok, path}

          {^subpath, path, true} ->
            IO.warn("File #{path} already checked out")
            {:ok, path}

          nil ->
            {:error, :not_found}
        end

      case found do
        {:ok, path} ->
          suite = path |> File.read!() |> Jason.decode!()
          {suite, %{state | files: List.keyreplace(files, subpath, 0, {subpath, path, true})}}

        {:error, :not_found} ->
          raise "Test case not found: #{subpath}"
      end
    end)
  end

  def stop_warn_unchecked(agent) do
    {unchecked, dir} =
      Agent.get(agent, fn state ->
        {Enum.filter(state.files, fn {_subpath, _path, checked?} -> not checked? end), state.dir}
      end)

    Agent.stop(agent)

    if unchecked != [] do
      total = length(unchecked)
      maxprint = 10
      more? = total > maxprint

      print_list =
        unchecked
        |> Enum.take(maxprint)
        |> Enum.map_intersperse(?\n, fn {filename, _, false} ->
          "- #{filename}"
        end)

      """
      Unchecked test cases in #{dir}:
      #{print_list}
      #{(more? && "... (#{total - maxprint} more)") || ""}
      """
      |> IO.warn([])
    end
  end
end
