# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Application.ensure_all_started(:tzdata)

# Run migrations for the test database
# Gracefully handle missing dependencies that may fail compilation
try do
  Ecto.Migrator.run(AriaPlanner.Repo, :up, all: true)
rescue
  e ->
    # If migrations fail due to missing dependencies, log and continue
    # Tests that don't need the database will still run
    IO.puts("Warning: Database migrations skipped due to: #{inspect(e)}")
end

ExUnit.start()
