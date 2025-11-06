# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

config :aria_planner,
  ecto_repos: [AriaPlanner.Repo]

config :aria_planner, AriaPlanner.Repo,
  database: Path.join(["priv", "aria_planner_#{Mix.env()}.db"]),
  pool_size: 10

