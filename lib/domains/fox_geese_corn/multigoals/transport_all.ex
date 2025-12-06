# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Multigoals.TransportAll do
  @moduledoc """
  Multigoal Method: m_transport_all(state)

  Transport all items from west to east side (goal-based).

  Returns a list of goals to achieve.
  """

  alias AriaPlanner.Domains.FoxGeeseCorn.Predicates.{
    WestFox,
    WestGeese,
    WestCorn
  }

  @spec m_transport_all(state :: map()) :: [tuple()]
  def m_transport_all(state) do
    # Check if goal is achieved
    if goal_achieved?(state) do
      []
    else
      # Generate goals for transporting items
      west_fox = WestFox.get(state)
      west_geese = WestGeese.get(state)
      west_corn = WestCorn.get(state)

      goals = []

      goals =
        if west_fox > 0 do
          goals ++ [{"east_fox", ["value", west_fox]}]
        else
          goals
        end

      goals =
        if west_geese > 0 do
          goals ++ [{"east_geese", ["value", west_geese]}]
        else
          goals
        end

      goals =
        if west_corn > 0 do
          goals ++ [{"east_corn", ["value", west_corn]}]
        else
          goals
        end

      goals
    end
  end

  defp goal_achieved?(state) do
    WestFox.get(state) == 0 and
      WestGeese.get(state) == 0 and
      WestCorn.get(state) == 0
  end
end
