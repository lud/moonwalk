defmodule Moonwalk.MixProject do
  use Mix.Project

  def project do
    [
      app: :moonwalk,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:json_schema_test_suite,
       git: "https://github.com/json-schema-org/JSON-Schema-Test-Suite.git",
       tag: "bf0360f4b7c51b8f968aabe7f3f49e12b120fc85",
       only: [:test],
       compile: false,
       app: false}
    ]
  end
end
