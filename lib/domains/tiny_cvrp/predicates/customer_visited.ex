# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrp.Predicates.CustomerVisited do
  @moduledoc """
  Customer Visited predicate for tiny-cvrp domain.
  
  Represents whether a customer has been visited (true/false).
  """

  @doc """
  Gets whether a customer has been visited from state.
  """
  @spec get(state :: map(), customer :: integer()) :: boolean()
  def get(state, customer) do
    Map.get(state.customer_visited, customer, false)
  end

  @doc """
  Sets the visited status of a customer in state.
  """
  @spec set(state :: map(), customer :: integer(), visited :: boolean()) :: map()
  def set(state, customer, visited) do
    new_customer_visited = Map.put(state.customer_visited, customer, visited)
    Map.put(state, :customer_visited, new_customer_visited)
  end
end

