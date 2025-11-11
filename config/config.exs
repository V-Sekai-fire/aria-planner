# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

config :aria_planner,
  ecto_repos: [AriaPlanner.Repo]

# Base database config - overridden by environment-specific configs
# Test environment uses :memory: database (configured in config/test.exs)
if Mix.env() != :test do
  config :aria_planner, AriaPlanner.Repo,
    database: Path.join(["priv", "aria_planner_#{Mix.env()}.db"]),
    pool_size: 10
end

