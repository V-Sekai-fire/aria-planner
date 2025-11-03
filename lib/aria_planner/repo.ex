# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo do
  use Ecto.Repo,
    otp_app: :aria_planner,
    adapter: Ecto.Adapters.SQLite3
end
