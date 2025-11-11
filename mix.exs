# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_planner,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "AI planner for complex decision-making",
      package: package(),
      test_coverage: [output: "cover"],
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :sasl, :tools, :xmerl, :tzdata],
      mod: {AriaPlanner.Planner.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.13"},
      {:jason, "~> 1.4"},
      {:axon, "~> 0.7.0"},
      {:timex, "~> 3.7"},
      {:uuidv7, "~> 1.0"},
      {:nx, "~> 0.10"},
      {:torchx, "~> 0.10", optional: true},
      {:aria_math, git: "https://github.com/V-Sekai-fire/aria-math.git"},
      {:exqlite, "~> 0.33.1"}, # Added for SQLite3 adapter
      {:ecto_sqlite3, "~> 0.22.0"}, # Added for SQLite3 Ecto adapter
      {:aria_core, git: "https://github.com/V-Sekai-fire/aria-core.git"},
      {:aria_storage, git: "https://github.com/V-Sekai-fire/aria-storage.git", ref: "2ae9d51537a7272d489663c56206731312c961aa"},
      {:abnf_parsec, "~> 2.1"},
      {:sourceror, "~> 1.10"},
      # Using built-in :zstd module from Erlang/OTP 28+ (no external dependency needed)
      # Dev/test dependencies
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev}
    ]
  end

  defp aliases do
    []
  end

  defp package do
    [
      maintainers: ["K. S. Ernest (iFire) Lee"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/V-Sekai-fire/aria-hybrid-planner"},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md c_src priv)
    ]
  end
end
