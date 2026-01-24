defmodule AriaPlanner.Domains.BlocksWorld.Tasks.Get do
  @moduledoc """
  Task for getting (picking up) a block.

  This task composes interactivity commands to implement the pickup operation.
  """

  @doc """
  Decomposes getting a block into interactivity commands.

  ## Parameters

  - state: The current planning state
  - block: The block identifier

  ## Returns

  A keyword list of interactivity commands.
  """
  def t_get(state, block) do
    [
      # Log the pickup action
      {:c_debug_log, state, "Picking up block #{block}"},

      # Set the holding state variable
      {:c_set_variable, state, "holding", block},

      # Clear the block's position (it's now in hand)
      {:c_set_variable, state, "pos_#{block}", nil},

      # Trigger custom event for pickup
      {:c_trigger_event, state, "block_picked_up", %{"block" => block}}
    ]
  end
end
