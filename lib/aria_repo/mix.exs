# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaRepo.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_repo,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Database repository utilities",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaRepo.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.19"},
      {:jason, "~> 1.4"}
    ]
  end

  defp package do
    [
      maintainers: ["K. S. Ernest (iFire) Lee"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/V-Sekai-fire/aria-hybrid-planner"},
      files: ~w(lib mix.exs README.md LICENSE.md)
    ]
  end
end
