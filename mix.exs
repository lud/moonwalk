defmodule Moonwalk.MixProject do
  use Mix.Project

  def project do
    [
      app: :moonwalk,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [],
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  defp elixirc_paths(:prod) do
    ["lib"]
  end

  defp elixirc_paths(_) do
    ["lib", "test/support"]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:jsv, "~> 0.7"},
      {:jsv, path: "../jsv"},
      {:phoenix, ">= 1.7.0"},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :test, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.16.0", only: [:dev, :test], runtime: false},

      # Test
      # {:phoenix, "~> 1.8.0-rc", only: [:dev, :test]},
      {:bandit, "~> 1.0", only: [:dev, :test]}
    ]
  end

  def cli do
    [
      preferred_envs: [
        dialyzer: :test,
        "mnwk.phx.test": :test
      ]
    ]
  end

  defp dialyzer do
    [
      flags: [:unmatched_returns, :error_handling, :unknown, :extra_return],
      list_unused_filters: true,
      plt_add_deps: :app_tree,
      plt_add_apps: [:ex_unit],
      plt_local_path: "_build/plts"
    ]
  end
end
