# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Application.ensure_all_started(:tzdata)

# Run migrations for the test database
Ecto.Migrator.run(AriaPlanner.Repo, :up, all: true)

ExUnit.start()
