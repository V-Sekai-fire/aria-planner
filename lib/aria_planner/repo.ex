# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Repo do
  @moduledoc """
  Ecto repository for Aria Planner.

  This repository connects to Supabase PostgreSQL database.
  """

  use Ecto.Repo,
    otp_app: :aria_planner,
    adapter: Ecto.Adapters.Postgres
end
