# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# This file is responsible for configuring your application
# in the test environment.

import Config

# Configure the database for testing
# Uses local PostgreSQL (can be started with mise)
config :aria_planner, AriaPlanner.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  database: System.get_env("DB_NAME", "aria_planner_test"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10")),
  ssl: System.get_env("DB_SSL", "false") == "true",
  # Use SQL sandbox for concurrent tests
  pool: Ecto.Adapters.SQL.Sandbox

# The test environment uses a separate database
# The database should be created and migrated before running tests
# Run: mix ecto.create && mix ecto.migrate

# Reduce log noise in test
config :logger, level: :warning
