# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.BlocksWorld.Tasks.AllBlocks do
  @moduledoc """
  Task: t_all_blocks()

  Return a list of all block IDs in the current state.
  """

  alias AriaPlanner.Domains.BlocksWorld.Pos
  alias AriaPlanner.Repo

  @spec t_all_blocks() :: [String.t()]
  def t_all_blocks do
    Repo.all(Pos)
    |> Enum.map(& &1.entity_id)
    |> Enum.uniq()
  end
end
