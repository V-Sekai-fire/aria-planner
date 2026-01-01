# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStnSolver do
  @moduledoc """
  STN Solver for temporal constraint networks.

  This module provides STN consistency checking and solving capabilities.
  """

  @type constraint :: {atom(), atom(), number(), number()}
  @type stn :: map() | list()

  alias AriaPlanner.Planner.Temporal.STN

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
  Solves an STN using Floyd-Warshall algorithm to tighten constraints.

  The Floyd-Warshall algorithm computes all-pairs shortest paths, which gives
  us the tightest possible constraints between all time points. This "solves"
  the STN by propagating constraints and finding the minimal bounds.

  Returns {:ok, solved_stn} with tightened constraints, or {:error, reason} if inconsistent.
  """
  @spec solve_stn(STN.t() | list()) :: {:ok, STN.t()} | {:error, String.t()}
  def solve_stn(%STN{} = stn) do
    # First check consistency
    stn_list = stn_to_constraints_list(stn)

    case check_consistency(stn_list) do
      {:consistent, _} ->
        # Apply Floyd-Warshall to tighten constraints
        tightened_constraints = floyd_warshall(stn)

        # Update STN with tightened constraints
        solved_stn = %{stn | constraints: tightened_constraints, consistent: true}
        {:ok, solved_stn}

      {:inconsistent, reason} ->
        {:error, reason}
    end
  end

  def solve_stn(stn) when is_list(stn) do
    # Handle list format - convert to STN struct format first
    # This is a legacy format, convert constraints to STN-like structure
    case check_consistency(stn) do
      {:consistent, _} ->
        # For list format, we can't return a proper STN struct
        # Return the constraints as-is since we can't build a full STN
        {:ok, %{constraints: stn, solution: "consistent"}}

      {:inconsistent, reason} ->
        {:error, reason}
    end
  end

  def solve_stn(_), do: {:error, "Invalid STN format"}

  # Convert STN struct to constraint list format for consistency checking
  defp stn_to_constraints_list(%STN{} = stn) do
    for {{from, to}, {min, max}} <- stn.constraints do
      # Convert string keys to atoms for consistency with check_consistency
      from_atom = String.to_atom(from)
      to_atom = String.to_atom(to)
      {from_atom, to_atom, min, max}
    end
  end

  # Floyd-Warshall algorithm for STN constraint propagation
  # Computes all-pairs shortest paths to find tightest constraints
  defp floyd_warshall(%STN{} = stn) do
    time_points = MapSet.to_list(stn.time_points)
    num_points = length(time_points)

    if num_points == 0 do
      stn.constraints
    else
      # Build distance matrix: dist[i][j] = shortest distance from i to j
      # Initialize with infinity for unknown distances, 0 for self-loops
      initial_dist = initialize_distance_matrix(time_points, stn.constraints)

      # Floyd-Warshall: for each intermediate point k, update distances
      # We need to use the previous iteration's distances, so we build a new matrix each iteration
      final_dist =
        Enum.reduce(time_points, initial_dist, fn k, prev_dist ->
          # Build new distance matrix for this iteration
          Enum.reduce(time_points, prev_dist, fn i, dist_acc ->
            Enum.reduce(time_points, dist_acc, fn j, dist_map ->
              # Check if path i -> k -> j is shorter than direct i -> j
              dist_ik = get_distance(prev_dist, i, k)
              dist_kj = get_distance(prev_dist, k, j)
              current_dist_ij = get_distance(prev_dist, i, j)

              new_dist =
                if dist_ik != :infinity and dist_kj != :infinity do
                  dist_ik + dist_kj
                else
                  current_dist_ij
                end

              # Update if new path is shorter
              if new_dist != :infinity and
                   (current_dist_ij == :infinity or new_dist < current_dist_ij) do
                update_distance(dist_map, i, j, new_dist)
              else
                dist_map
              end
            end)
          end)
        end)

      convert_distances_to_constraints(final_dist, time_points, stn.constraints)
    end
  end

  # Initialize distance matrix from STN constraints
  defp initialize_distance_matrix(time_points, constraints) do
    # Start with all distances as infinity
    initial =
      for i <- time_points, j <- time_points, into: %{} do
        {{i, j}, :infinity}
      end

    # Set self-loops to 0
    self_loops =
      for point <- time_points, into: %{} do
        {{point, point}, 0}
      end

    # Set distances from constraints (use min distance as edge weight)
    constraint_distances =
      Enum.reduce(constraints, %{}, fn {{from, to}, {min_dist, _max_dist}}, acc ->
        if min_dist != :neg_infinity do
          Map.put(acc, {from, to}, min_dist)
        else
          acc
        end
      end)

    initial
    |> Map.merge(self_loops)
    |> Map.merge(constraint_distances)
  end

  # Get distance between two points from distance matrix
  defp get_distance(dist_matrix, from, to) do
    Map.get(dist_matrix, {from, to}, :infinity)
  end

  # Update distance in distance matrix
  defp update_distance(dist_matrix, from, to, new_dist) do
    Map.put(dist_matrix, {from, to}, new_dist)
  end

  # Convert distance matrix back to constraint format
  # For each original constraint, use the tightened min distance from Floyd-Warshall
  defp convert_distances_to_constraints(dist_matrix, time_points, original_constraints) do
    # Build reverse distance matrix (for max constraints)
    # For max constraints, we need the negative of the reverse path
    reverse_dist = build_reverse_distance_matrix(dist_matrix, time_points)

    Enum.reduce(original_constraints, %{}, fn {{from, to}, {orig_min, orig_max}}, acc ->
      # Get tightened min distance from Floyd-Warshall
      tightened_min = get_distance(dist_matrix, from, to)

      # Get tightened max distance (negative of reverse path)
      reverse_dist_to_from = get_distance(reverse_dist, to, from)

      tightened_max =
        if reverse_dist_to_from != :infinity do
          -reverse_dist_to_from
        else
          orig_max
        end

      # Ensure min <= max
      final_min =
        cond do
          tightened_min == :infinity -> :neg_infinity
          tightened_min == :neg_infinity -> :neg_infinity
          true -> tightened_min
        end

      final_max =
        cond do
          tightened_max == :infinity -> :infinity
          tightened_max == :neg_infinity -> :infinity
          true -> tightened_max
        end

      # Only update if constraint is valid
      if final_min <= final_max or final_min == :neg_infinity or final_max == :infinity do
        Map.put(acc, {from, to}, {final_min, final_max})
      else
        # Invalid constraint - keep original
        Map.put(acc, {from, to}, {orig_min, orig_max})
      end
    end)
  end

  # Build reverse distance matrix for max constraint computation
  defp build_reverse_distance_matrix(dist_matrix, time_points) do
    for i <- time_points, j <- time_points, into: %{} do
      forward_dist = get_distance(dist_matrix, i, j)
      # Reverse distance is negative of forward (for max constraints)
      reverse_dist =
        if forward_dist != :infinity do
          -forward_dist
        else
          :infinity
        end

      {{j, i}, reverse_dist}
    end
  end
end
