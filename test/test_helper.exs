# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Application.ensure_all_started(:tzdata)

# ETS storage is initialized by the application
# Clear ETS tables before each test run for clean state
ExUnit.start()

# Setup callback to clear ETS storage between tests if needed
ExUnit.after_suite(fn _ ->
  AriaPlanner.Storage.EtsStorage.clear_all()
end)
