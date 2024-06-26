defmodule Mix.Tasks.Gen.Test.Suite do
  alias Moonwalk.Test.JsonSchemaSuite
  alias CliMate.CLI
  use Mix.Task
  require EEx

  @enabled_202012 [
    {"additionalProperties.json", []},
    {"allOf.json", []},
    {"anchor.json", []},
    {"anyOf.json", []},
    {"boolean_schema.json", []},
    {"const.json", []},
    {"contains.json", []},
    {"content.json", []},
    {"default.json", []},
    {"defs.json", []},
    {"dependentRequired.json", []},
    {"dependentSchemas.json", []},
    {"dynamicRef.json", []},
    {"enum.json", []},
    {"exclusiveMaximum.json", []},
    {"exclusiveMinimum.json", []},
    {"format.json", []},
    {"id.json", []},
    {"if-then-else.json", []},
    {"infinite-loop-detection.json", []},
    {"items.json", []},
    {"maxContains.json", []},
    {"maximum.json", []},
    {"maxItems.json", []},
    {"maxLength.json", []},
    {"maxProperties.json", []},
    {"minContains.json", []},
    {"minimum.json", []},
    {"minItems.json", []},
    {"minLength.json", []},
    {"minProperties.json", []},
    {"multipleOf.json", []},
    {"not.json", []},
    {"oneOf.json", []},
    {"pattern.json", []},
    {"patternProperties.json", []},
    {"prefixItems.json", []},
    {"properties.json", []},
    {"propertyNames.json", []},
    {"ref.json", []},
    {"refRemote.json", []},
    {"required.json", []},
    {"type.json", []},
    {"unevaluatedItems.json", []},
    {"unevaluatedProperties.json", []},
    {"uniqueItems.json", []},
    {"vocabulary.json", []},

    # Optional

    {"optional/anchor.json", []},
    {"optional/id.json", []},
    {"optional/no-schema.json", []},
    {"optional/bignum.json", []},
    {"optional/dependencies-compatibility.json", []},
    {"optional/format/ipv4.json", schema_build_opts: [formats: true]},
    {"optional/ecmascript-regex.json", :unsupported},

    # TODO we should be able to do cross-schema once we implement all the specs.
    {"optional/cross-draft.json", :unsupported},

    # Language incompatibilities. Elixir vs Javascript mostly.
    #
    {"optional/non-bmp-regex.json", :unsupported},
    {"optional/float-overflow.json", :unsupported},
    {"optional/format/time.json", :unsupported},

    # Formats
    {"optional/format-assertion.json", []},
    {"optional/format/ipv6.json", schema_build_opts: [formats: true]},
    {"optional/format/regex.json", schema_build_opts: [formats: true]},
    {"optional/format/unknown.json", schema_build_opts: [formats: true]},
    {"optional/format/date-time.json",
     schema_build_opts: [formats: true],
     ignore: [
       "case-insensitive T and Z",
       "a valid date-time with a leap second, UTC",
       "a valid date-time with a leap second, with minus offset"
     ]},
    {"optional/format/date.json", schema_build_opts: [formats: true]},

    # Not supported yet. TODO Maybe elixir 1.17 if the new Duration modules has
    # a correct parser.
    #
    {"optional/format/duration.json", :unsupported},

    # Needs custom implementations
    #
    {"optional/format/email.json", :unsupported},
    {"optional/format/hostname.json", :unsupported},
    {"optional/format/idn-email.json", :unsupported},
    {"optional/format/idn-hostname.json", :unsupported},
    {"optional/format/iri-reference.json", :unsupported},
    {"optional/format/iri.json", :unsupported},
    {"optional/format/json-pointer.json", :unsupported},
    {"optional/format/relative-json-pointer.json", :unsupported},
    {"optional/format/uri-reference.json", :unsupported},

    # We need to make a change so each vocabulary module exports a strict list
    # of supported keywords, and the resolver schema scanner does not
    # automatically build schemas under unknown keywords.
    {"optional/unknownKeyword.json", :unsupported}
  ]
  @enabled %{
    # "latest" => @enabled_202012,
    "draft2020-12" => @enabled_202012
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
    # credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
    defmodule <%= @module_name %> do
      alias Moonwalk.Test.JsonSchemaSuite
      use ExUnit.Case, async: true

      @moduledoc \"""
      Test generated from <%= Path.relative_to_cwd(@path) %>
      \"""

      <%= for tcase <- @test_cases do %>
        describe <%= inspect(tcase.description <> ":") %> do

          setup do
            json_schema = <%= inspect(tcase.schema, limit: :infinity, pretty: true) %>
            schema = JsonSchemaSuite.build_schema(json_schema, <%= inspect(@schema_build_opts, limit: :infinity, pretty: true) %>)
            {:ok, json_schema: json_schema, schema: schema}
          end

          <%= for ttest <- tcase.tests do %>
            <%= if ttest.skip?, do: "@tag :skip", else: "" %>
            test <%= inspect(ttest.description) %>, c do
              data = <%= inspect(ttest.data, limit: :infinity, pretty: true) %>
              expected_valid = <%= inspect(ttest.valid?) %>
              JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
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

    assigns =
      Map.merge(file_info, %{
        module_name: module_name,
        schema_build_opts: get_in(file_info, [:opts, :schema_build_opts]) || []
      })

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
