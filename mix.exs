defmodule Moonwalk.MixProject do
  use Mix.Project

  def project do
    [
      app: :moonwalk,
      description: "A tool to define API specifications adhering to the Moonwalk specification.",
      version: "0.0.1",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      modkit: modkit()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key, :crypto]
    ]
  end

  defp elixirc_paths(:prod) do
    ["lib"]
  end

  defp elixirc_paths(_) do
    ["lib", "test/support"]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:json_schema_test_suite,
       git: "https://github.com/json-schema-org/JSON-Schema-Test-Suite.git",
       ref: "9fc880bfb6d8ccd093bc82431f17d13681ffae8e",
       only: [:test],
       compile: false,
       app: false},
      {:decimal, "~> 2.1"},

      # Formats
      {:mail_address, "~> 1.0", optional: true},
      {:abnf_parsec, "~> 1.0", optional: true},
      {:ecto, "> 0.0.0", optional: true},

      # Test or Prod ?
      {:ex_ssl_options, "~> 0.1.0"},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:modkit, "~> 0.6", only: [:dev, :test], runtime: false},

      # Test
      {:excoveralls, "~> 0.18.0", only: :test},
      {:mutex, "~> 3.0", only: :test}
    ]
  end

  defp package do
    [licenses: ["MIT"], links: %{"Github" => "https://github.com/lud/moonwalk"}]
  end

  def cli do
    [preferred_envs: ["coveralls.html": :test, "gen.test.suite": :test]]
  end

  defp modkit do
    [
      mount: [
        {Moonwalk, "lib/moonwalk"},
        {Moonwalk.Test, "test/support"}
      ]
    ]
  end
end
