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
      aliases: aliases()
    ]
  end

  def cli do
    [
      preferred_envs: [
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
      mod: {AriaPlanner.Planner.Application, []},
      env: [ecto_repos: [AriaPlanner.Repo]]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:axon, "~> 0.8"},
      {:timex, "~> 3.7.13"},
      {:uuidv7, "~> 1.0"},
      {:nx, "~> 0.10"},
      {:torchx, "~> 0.10", optional: true},
      {:aria_math, git: "https://github.com/V-Sekai-fire/aria-math.git"},
      {:aria_core, git: "https://github.com/V-Sekai-fire/aria-core.git"},
      {:abnf_parsec, "~> 2.1"},
      {:sourceror, "~> 1.10"},
      {:fun_with_flags, "~> 1.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      # Using built-in :zstd module from Erlang/OTP 28+ (no external dependency needed)
      # Dev/test dependencies
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp package do
    [
      maintainers: ["K. S. Ernest (iFire) Lee"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/V-Sekai-fire/aria-hybrid-planner"},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md)
    ]
  end
end
