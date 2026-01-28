defmodule AriaPlanner.Domains.BlocksWorld.Tasks.MoveBlocks do
  @moduledoc """
  Task for moving multiple blocks to achieve a goal state.

  This task decomposes into individual block move operations.
  """

  alias AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne

  @doc """
  Decomposes moving multiple blocks into individual move operations.

  ## Parameters

  - state: The current planning state
  - goal_state: A map of block_id -> destination pairs

  ## Returns

  A keyword list of interactivity commands and subtasks.
  """
  def t_move_blocks(state, goal_state) when is_map(goal_state) do
    goal_state
    |> Enum.map(fn {block, destination} ->
      MoveOne.t_move_one(state, block, destination)
    end)
    |> List.flatten()
  end

  def t_move_blocks(_state, _goal_state), do: []
end
