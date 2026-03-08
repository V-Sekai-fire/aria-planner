# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.FixtureHelpers do
  @moduledoc """
  Load JSON fixtures for plan and domain tests. Plan inputs and expected results
  live in test/fixtures/ so tests stay fixture-driven across all domains.
  """

  def fixture_path(name, subdir \\ "") do
    base = Path.join([File.cwd!(), "test", "fixtures"])
    path = if subdir != "", do: Path.join([base, subdir, "#{name}.json"]), else: Path.join([base, "#{name}.json"])
    path
  end

  def load_fixture(name, subdir \\ "") do
    path = fixture_path(name, subdir)
    {:ok, json} = File.read(path)
    Jason.decode!(json)
  end
end
