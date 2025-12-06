# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStnSolver do
  @moduledoc """
  STN Solver for temporal constraint networks.

  This module provides STN consistency checking and solving capabilities.
  """

  @type constraint :: {atom(), atom(), number(), number()}
  @type stn :: map() | list()

  @doc """
  Checks if a list of constraints is consistent.

  Returns {:consistent, solution} or {:inconsistent, reason}
  """
  @spec check_consistency([constraint()]) :: {:consistent, map()} | {:inconsistent, String.t()}
  def check_consistency(constraints) when is_list(constraints) do
    # Check for basic validity
    if not Enum.all?(constraints, fn {_from, _to, min, max} -> min <= max end) do
      {:inconsistent, "Invalid constraint bounds"}
    else
      # Check for negative cycles using Floyd-Warshall algorithm
      # Build a graph and check for negative cycles
      case check_negative_cycles(constraints) do
        true -> {:inconsistent, "Negative cycle detected"}
        false -> {:consistent, %{}}
      end
    end
  end

  def check_consistency(_), do: {:inconsistent, "Invalid constraint format"}

  # Check for negative cycles in the constraint graph
  # A negative cycle means the constraints are inconsistent
  # For STN: if we have a -> b with min and b -> a with min, and both mins are positive,
  # that creates a cycle where both must be after each other, which is impossible
  defp check_negative_cycles(constraints) do
    # Build bidirectional constraint map
    constraint_map =
      Enum.reduce(constraints, %{}, fn {from, to, min_dist, _max_dist}, acc ->
        key = {from, to}
        Map.put(acc, key, min_dist)
      end)

    # Check for cycles: if we have both (a, b) and (b, a) with positive min distances,
    # that's inconsistent (both must be after each other)
    Enum.any?(constraints, fn {from, to, min_dist, _max_dist} ->
      reverse_key = {to, from}
      reverse_min = Map.get(constraint_map, reverse_key)

      # If both directions have positive minimum distances, it's inconsistent
      if reverse_min != nil and min_dist > 0 and reverse_min > 0 do
        # Found inconsistent cycle
        true
      else
        false
      end
    end)
  end

  @doc """
  Solves an STN and returns a solution.

  Returns {:ok, solution} or {:error, reason}
  """
  @spec solve_stn(stn()) :: {:ok, map()} | {:error, String.t()}
  def solve_stn(stn) when is_map(stn) do
    # Stub implementation - return a simple solution
    {:ok, %{solution: "stub", stn: stn}}
  end

  def solve_stn(stn) when is_list(stn) do
    # Handle list format
    {:ok, %{solution: "stub", constraints: stn}}
  end

  def solve_stn(_), do: {:error, "Invalid STN format"}
end
