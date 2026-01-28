# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

# Configure Ecto repositories
config :aria_planner, ecto_repos: [AriaPlanner.Repo]

# Configure FunWithFlags with Ecto persistence
config :fun_with_flags, :cache,
  enabled: true,
  ttl: 900

# Configure FunWithFlags to use Ecto adapter with UUID primary keys
# The repo will be configured in runtime.exs
config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: AriaPlanner.Repo,
  ecto_primary_key_type: :binary_id

# Disable cache-bust notifications for single-node setup
# Enable Phoenix.PubSub if you need multi-node synchronization
config :fun_with_flags, :cache_bust_notifications, enabled: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
