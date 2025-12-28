# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Application.ensure_all_started(:tzdata)

# Initialize ETS storage for tests
AriaPlanner.Storage.EtsStorage.start_link()

ExUnit.start()
