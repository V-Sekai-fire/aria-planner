# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure the database for development
config :aria_planner, AriaPlanner.Repo,
  database: Path.join(["priv", "aria_planner_dev.db"]),
  pool_size: 10

