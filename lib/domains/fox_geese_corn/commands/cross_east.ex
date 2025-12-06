# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.FoxGeeseCorn.Commands.CrossEast do
  @moduledoc """
  Command: c_cross_east(fox_count, geese_count, corn_count)

  Cross the river from west to east with specified items.

  Preconditions:
  - Boat is on west side
  - Sufficient items on west side
  - Total items <= boat capacity
  - At least one item must be transported
  - Resulting state must be safe

  Effects:
  - Items move from west to east
  - Boat moves to east side
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

  @spec c_cross_east(state :: map(), fox_count :: integer(), geese_count :: integer(), corn_count :: integer()) ::
          {:ok, map()} | {:error, String.t()}
  def c_cross_east(state, fox_count, geese_count, corn_count) do
    with :ok <- check_boat_location(state),
         :ok <- check_capacity(state, fox_count, geese_count, corn_count),
         :ok <- check_sufficient_items(state, fox_count, geese_count, corn_count),
         :ok <- check_at_least_one_item(fox_count, geese_count, corn_count) do
      # Calculate new state
      new_state =
        state
        |> WestFox.set(WestFox.get(state) - fox_count)
        |> WestGeese.set(WestGeese.get(state) - geese_count)
        |> WestCorn.set(WestCorn.get(state) - corn_count)
        |> EastFox.set(EastFox.get(state) + fox_count)
        |> EastGeese.set(EastGeese.get(state) + geese_count)
        |> EastCorn.set(EastCorn.get(state) + corn_count)
        |> BoatLocation.set("east")

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
  @spec c_cross_east(state :: map(), items :: map()) :: {:ok, map()} | {:error, String.t()}
  def c_cross_east(state, %{fox: fox, geese: geese, corn: corn}) do
    c_cross_east(state, fox, geese, corn)
  end

  def c_cross_east(state, items) when is_map(items) do
    c_cross_east(state, Map.get(items, :fox, 0), Map.get(items, :geese, 0), Map.get(items, :corn, 0))
  end

  # Private helper functions

  defp check_boat_location(state) do
    if BoatLocation.get(state) == "west" do
      :ok
    else
      {:error, "Boat must be on west side to cross east"}
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
    if WestFox.get(state) >= fox_count and
         WestGeese.get(state) >= geese_count and
         WestCorn.get(state) >= corn_count do
      :ok
    else
      {:error, "Insufficient items on west side"}
    end
  end

  defp check_at_least_one_item(fox_count, geese_count, corn_count) do
    if fox_count + geese_count + corn_count > 0 do
      :ok
    else
      {:error, "Must transport at least one item"}
    end
  end
end
