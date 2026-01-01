# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# Debug JSON loading
expected_solutions = Jason.decode!(File.read!("test/fixtures/minizinc_expected_solutions.json"))

IO.inspect(Map.keys(expected_solutions), label: "Top-level keys")
IO.inspect(Map.keys(expected_solutions["neighbours"] || %{}), label: "Neighbours keys")
