# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure the database for production
config :aria_planner, AriaPlanner.Repo,
  database: System.get_env("DATABASE_PATH", Path.join(["priv", "aria_planner_prod.db"])),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))
