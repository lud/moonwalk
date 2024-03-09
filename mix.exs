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
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key, :crypto]
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
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

      # Test or Prod ?
      {:ex_ssl_options, "~> 0.1.0"},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [licenses: ["MIT"], links: %{"Github" => "https://github.com/lud/moonwalk"}]
  end
end
