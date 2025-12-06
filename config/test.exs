# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure the database for tests - use in-memory database
config :aria_planner, AriaPlanner.Repo,
  database: ":memory:",
  pool_size: 10
