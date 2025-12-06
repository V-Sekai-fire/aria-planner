# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Tasks.TransportAll do
  @moduledoc """
  Task: t_transport_all(state)

  Transport all items from west to east side.

  This task decomposes into a sequence of crossing actions.
  Returns a list of subtasks to execute.
  """

  alias AriaPlanner.Domains.FoxGeeseCorn.Predicates.{
    WestFox,
    WestGeese,
    WestCorn,
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

    # Simple strategy: transport as much as possible
    # Priority: geese (most valuable), then corn, then fox
    cond do
      west_geese > 0 and capacity >= 1 ->
        [{"c_cross_east", 0, min(west_geese, capacity), 0}, {"t_transport_all", state}]

      west_corn > 0 and capacity >= 1 ->
        [{"c_cross_east", 0, 0, min(west_corn, capacity)}, {"t_transport_all", state}]

      west_fox > 0 and capacity >= 1 ->
        [{"c_cross_east", min(west_fox, capacity), 0, 0}, {"t_transport_all", state}]

      true ->
        []
    end
  end

  defp generate_east_to_west_crossing(state) do
    # Return empty boat to west side
    [{"c_cross_west", 0, 0, 0}, {"t_transport_all", state}]
  end
end
