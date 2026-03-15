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

# Optional: override feature flags (defaults all true)
# config :aria_planner, :feature_flags, [gltf_asset: true, pointer_template: true, gltf_loader: true]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
