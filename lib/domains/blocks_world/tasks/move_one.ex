defmodule AriaPlanner.Domains.BlocksWorld.Tasks.MoveOne do
  @moduledoc """
  Task for moving a single block to a destination.

  This task decomposes into get and put operations.
  """

  alias AriaPlanner.Domains.BlocksWorld.Tasks.Get
  alias AriaPlanner.Domains.BlocksWorld.Tasks.Put

  @doc """
  Decomposes moving a block into get and put operations.

  ## Parameters

  - state: The current planning state
  - block: The block identifier
  - destination: The destination (another block or "table")

  ## Returns

  A keyword list of interactivity commands and subtasks.
  """
  def t_move_one(state, block, destination) do
    Get.t_get(state, block) ++ Put.t_put(state, block, destination)
  end
end
