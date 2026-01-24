defmodule AriaPlanner.Domains.BlocksWorld.Tasks.Put do
  @moduledoc """
  Task for putting (placing) a block at a destination.

  This task composes interactivity commands to implement the put operation.
  """

  @doc """
  Decomposes putting a block into interactivity commands.

  ## Parameters

  - state: The current planning state
  - block: The block identifier
  - destination: The destination (another block or "table")

  ## Returns

  A keyword list of interactivity commands.
  """
  def t_put(state, block, destination) do
    [
      # Log the put action
      {:c_debug_log, state, "Putting block #{block} on #{destination}"},

      # Set the block's position
      {:c_set_variable, state, "pos_#{block}", destination},

      # Clear the holding state
      {:c_set_variable, state, "holding", nil},

      # Trigger custom event for put
      {:c_trigger_event, state, "block_put_down", %{"block" => block, "destination" => destination}}
    ]
  end
end
