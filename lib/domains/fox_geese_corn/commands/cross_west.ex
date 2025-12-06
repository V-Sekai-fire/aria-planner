# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Commands.CrossWest do
  @moduledoc """
  Command: c_cross_west(fox_count, geese_count, corn_count)

  Cross the river from east to west with specified items.

  Preconditions:
  - Boat is on east side
  - Sufficient items on east side
  - Total items <= boat capacity
  - Resulting state must be safe

  Effects:
  - Items move from east to west
  - Boat moves to west side
  """

  alias AriaPlanner.Domains.FoxGeeseCorn.Predicates.{
    WestFox,
    WestGeese,
    WestCorn,
    EastFox,
    EastGeese,
    EastCorn,
    BoatLocation
  }

  alias AriaPlanner.Domains.FoxGeeseCorn

  defstruct fox: 0, geese: 0, corn: 0

  @spec c_cross_west(state :: map(), fox_count :: integer(), geese_count :: integer(), corn_count :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_cross_west(state, fox_count, geese_count, corn_count) do
    with :ok <- check_boat_location(state),
         :ok <- check_capacity(state, fox_count, geese_count, corn_count),
         :ok <- check_sufficient_items(state, fox_count, geese_count, corn_count),
         :ok <- check_at_least_one_item_or_empty_return(fox_count, geese_count, corn_count) do
      # Calculate new state
      new_state =
        state
        |> EastFox.set(EastFox.get(state) - fox_count)
        |> EastGeese.set(EastGeese.get(state) - geese_count)
        |> EastCorn.set(EastCorn.get(state) - corn_count)
        |> WestFox.set(WestFox.get(state) + fox_count)
        |> WestGeese.set(WestGeese.get(state) + geese_count)
        |> WestCorn.set(WestCorn.get(state) + corn_count)
        |> BoatLocation.set("west")

      # Check safety constraints
      if FoxGeeseCorn.is_safe?(new_state) do
        {:ok, new_state}
      else
        {:error, "Crossing would result in unsafe state"}
      end
    else
      error -> error
    end
  end

  # Convenience function that takes a map
  @spec c_cross_west(state :: map(), items :: map()) :: {:ok, map()} | {:error, String.t()}
  def c_cross_west(state, %{fox: fox, geese: geese, corn: corn}) do
    c_cross_west(state, fox, geese, corn)
  end

  def c_cross_west(state, items) when is_map(items) do
    c_cross_west(state, Map.get(items, :fox, 0), Map.get(items, :geese, 0), Map.get(items, :corn, 0))
  end

  # Private helper functions

  defp check_boat_location(state) do
    if BoatLocation.get(state) == "east" do
      :ok
    else
      {:error, "Boat must be on east side to cross west"}
    end
  end

  defp check_capacity(state, fox_count, geese_count, corn_count) do
    total = fox_count + geese_count + corn_count
    capacity = Map.get(state, :boat_capacity, 2)

    if total <= capacity do
      :ok
    else
      {:error, "Total items (#{total}) exceeds boat capacity (#{capacity})"}
    end
  end

  defp check_sufficient_items(state, fox_count, geese_count, corn_count) do
    if EastFox.get(state) >= fox_count and
         EastGeese.get(state) >= geese_count and
         EastCorn.get(state) >= corn_count do
      :ok
    else
      {:error, "Insufficient items on east side"}
    end
  end

  defp check_at_least_one_item_or_empty_return(fox_count, geese_count, corn_count) do
    total = fox_count + geese_count + corn_count
    # Allow empty return (total == 0) or at least one item
    if total == 0 or total > 0 do
      :ok
    else
      {:error, "Must transport at least one item or return empty"}
    end
  end
end
