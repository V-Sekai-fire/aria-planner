# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# This file is responsible for configuring your application
# in the development environment.

import Config

# Configure the database for development
# Uses local PostgreSQL (can be started with mise)
config :aria_planner, AriaPlanner.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  database: System.get_env("DB_NAME", "aria_planner_dev"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10")),
  ssl: System.get_env("DB_SSL", "false") == "true"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher log level in development
config :logger, level: :debug
