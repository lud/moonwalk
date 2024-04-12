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
      package: package()
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
       tag: "bf0360f4b7c51b8f968aabe7f3f49e12b120fc85",
       only: [:test],
       compile: false,
       app: false},
      {:decimal, "~> 2.1"},

      # Test or Prod ?
      {:ex_ssl_options, "~> 0.1.0"},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.0"},
      {:cli_mate, "~> 0.3.0", only: [:dev, :test]},
      {:modkit, "~> 0.5.1", only: [:dev, :test]}
    ]
  end

  defp package do
    [licenses: ["MIT"], links: %{"Github" => "https://github.com/lud/moonwalk"}]
  end

  def cli do
    [preferred_envs: ["coveralls.html": :test]]
  end
end
