# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Tasks.TransportAll do
  @moduledoc """
  Task: t_transport_all(state)

  Transport all items from west to east side.

  This task decomposes into a sequence of crossing actions.
  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.FoxGeeseCorn

  alias AriaPlanner.Domains.FoxGeeseCorn.Predicates.{
    WestFox,
    WestGeese,
    WestCorn,
    EastFox,
    EastGeese,
    EastCorn,
    BoatLocation
  }

  @spec t_transport_all(state :: map()) :: [tuple()]
  def t_transport_all(state) do
    # Check if goal is achieved
    if goal_achieved?(state) do
      []
    else
      # Generate next crossing action
      case BoatLocation.get(state) do
        "west" ->
          generate_west_to_east_crossing(state)

        "east" ->
          generate_east_to_west_crossing(state)
      end
    end
  end

  defp goal_achieved?(state) do
    WestFox.get(state) == 0 and
      WestGeese.get(state) == 0 and
      WestCorn.get(state) == 0
  end

  defp generate_west_to_east_crossing(state) do
    west_fox = WestFox.get(state)
    west_geese = WestGeese.get(state)
    west_corn = WestCorn.get(state)
    capacity = Map.get(state, :boat_capacity, 2)

    # Try actions in priority order, but only if they would be safe
    # Priority: geese (most valuable), then corn, then fox
    # Also try combinations when capacity allows
    cond do
      # Try transporting geese alone (safe if fox and corn together on west)
      west_geese > 0 and capacity >= 1 and would_be_safe_after_crossing?(state, 0, 1, 0) ->
        [{"c_cross_east", 0, 1, 0}, {"t_transport_all", state}]

      # Try transporting fox and corn together (safe if geese already on east or all together)
      west_fox > 0 and west_corn > 0 and capacity >= 2 and would_be_safe_after_crossing?(state, 1, 0, 1) ->
        [{"c_cross_east", 1, 0, 1}, {"t_transport_all", state}]

      # Try transporting fox alone (safe if geese and corn together on west)
      west_fox > 0 and capacity >= 1 and would_be_safe_after_crossing?(state, 1, 0, 0) ->
        [{"c_cross_east", 1, 0, 0}, {"t_transport_all", state}]

      # Try transporting corn alone (safe if fox and geese together on west)
      west_corn > 0 and capacity >= 1 and would_be_safe_after_crossing?(state, 0, 0, 1) ->
        [{"c_cross_east", 0, 0, 1}, {"t_transport_all", state}]

      # Try transporting geese and corn together (if capacity allows)
      west_geese > 0 and west_corn > 0 and capacity >= 2 and would_be_safe_after_crossing?(state, 0, 1, 1) ->
        [{"c_cross_east", 0, 1, 1}, {"t_transport_all", state}]

      # Try transporting fox and geese together (if capacity allows)
      west_fox > 0 and west_geese > 0 and capacity >= 2 and would_be_safe_after_crossing?(state, 1, 1, 0) ->
        [{"c_cross_east", 1, 1, 0}, {"t_transport_all", state}]

      true ->
        []
    end
  end

  # Check if the state would be safe after crossing with given items
  defp would_be_safe_after_crossing?(state, fox_count, geese_count, corn_count) do
    # Calculate what the state would be after crossing
    west_fox = WestFox.get(state) - fox_count
    west_geese = WestGeese.get(state) - geese_count
    west_corn = WestCorn.get(state) - corn_count
    east_fox = EastFox.get(state) + fox_count
    east_geese = EastGeese.get(state) + geese_count
    east_corn = EastCorn.get(state) + corn_count

    new_state = %{
      state
      | west_fox: west_fox,
        west_geese: west_geese,
        west_corn: west_corn,
        east_fox: east_fox,
        east_geese: east_geese,
        east_corn: east_corn,
        boat_location: "east"
    }

    FoxGeeseCorn.is_safe?(new_state)
  end

  defp generate_east_to_west_crossing(state) do
    # Return empty boat to west side
    [{"c_cross_west", 0, 0, 0}, {"t_transport_all", state}]
  end
end
