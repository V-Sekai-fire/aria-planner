# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Predicates.Distance do
  @moduledoc """
  Distance predicate for tiny-cvrp domain.
  
  Represents the distance/ETA between two locations.
  """

  @doc """
  Gets the distance between two locations from state.
  """
  @spec get(state :: map(), from :: integer(), to :: integer()) :: integer() | nil
  def get(state, from, to) do
    case state.predicted_ETAs do
      %{} = matrix when is_map(matrix) ->
        Map.get(matrix, {from, to})

      list when is_list(list) ->
        # Handle 2D array representation
        if from <= length(list) and to <= length(Enum.at(list, from - 1, [])) do
          Enum.at(Enum.at(list, from - 1, []), to - 1)
        else
          nil
        end

      _ ->
        nil
    end
  end
end

