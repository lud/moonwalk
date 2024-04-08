defmodule Mix.Tasks.Gen.Test.Suite do
  alias Moonwalk.Test.JsonSchemaSuite
  alias CliMate.CLI
  use Mix.Task
  require EEx

  @enabled %{
    "draft2020-12" => [
      {"format.json", []},
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
    ]
  }

  @command [
    module: __MODULE__,
    arguments: [
      suite: [
        type: :string,
        short: :s,
        doc: """
        The json test suite in 'draft2019-09', 'draft2020-12', 'draft3', 'draft4',
        'draft6', 'draft7', 'draft-next' or 'latest'.
        """
      ]
    ],
    options: []
  ]

  EEx.function_from_string(
    :defp,
    :module_template,
    ~S"""
    defmodule <%= @module_name %> do
      alias Moonwalk.Test.JsonSchemaSuite
      use ExUnit.Case, async: true

      @moduledoc \"""
      Test generated from <%= Path.relative_to_cwd(@source_path) %>
      \"""


      <%= for tcase <- @test_cases do %>
        describe <%= inspect(tcase.description) %> do

          setup do
            schema = <%= inspect(tcase.schema, limit: :infinity, pretty: true) %>
            {:ok, schema: schema}
          end

          <%= for ttest <- tcase.tests do %>
            <%= if ttest.skip?, do: "@tag :skip", else: "" %>
            test <%= inspect(ttest.description) %>, %{schema: schema} do
              data = <%= inspect(ttest.data, limit: :infinity, pretty: true) %>
              expected_valid = <%= inspect(ttest.valid?) %>
              JsonSchemaSuite.run_test(schema, data, expected_valid)
            end
          <% end %>
        end
      <% end %>
    end
    """,
    [
      :assigns
    ]
  )

  @impl true
  def run(argv) do
    %{options: _options, arguments: %{suite: suite}} = CLI.parse_or_halt!(argv, @command)

    do_run(suite)
    Mix.Task.run("format")
  end

  defp do_run(suite) do
    test_directory = "test/generated/#{suite}"
    namespace = Module.concat([Moonwalk, Generated, Macro.camelize(String.replace(suite, "-", ""))])

    CLI.warn("Deleting current test files directory #{test_directory}")
    File.rm_rf!(test_directory)

    config = @enabled |> Map.get(suite, []) |> Map.new()

    suite
    |> JsonSchemaSuite.stream_cases(config)
    |> Enum.each(&gen_test_mod(&1, test_directory, namespace))
  end

  defp gen_test_mod(file_info, test_directory, namespace) do
    module_name = module_name(file_info, namespace)
    assigns = %{module_name: module_name, test_cases: file_info.test_cases, source_path: file_info.path}
    module_contents = module_template(assigns)
    module_path = module_path(test_directory, namespace, module_name)

    File.mkdir_p!(Path.dirname(module_path))
    File.write!(module_path, module_contents)
    CLI.writeln(["Created module ", inspect(module_name), " in ", module_path])
  end

  @re_modpath ~r/\.ex$/

  defp module_path(test_directory, namespace, module_name) do
    mount = Modkit.Mount.define!([{namespace, test_directory}])
    {:ok, path} = Modkit.Mount.preferred_path(mount, module_name)

    mod_path = Regex.replace(@re_modpath, path, ".exs")
    true = String.ends_with?(mod_path, ".exs")
    mod_path
  end

  defp module_name(file_info, namespace) do
    mod_name =
      file_info.rel_path
      |> String.replace("optional/", "optional.")
      |> Path.basename(".json")
      |> Macro.underscore()
      |> String.replace(~r/[^A-Za-z0-9.\/]/, "_")
      |> Macro.camelize()
      |> Kernel.<>("Test")

    module = Module.concat(namespace, mod_name)

    case inspect(module) do
      ~s(:"Elixir) <> _ -> raise "invalid module: #{inspect(module)}"
      _ -> module
    end
  end
end
