# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Neighbours do
  @moduledoc """
  Neighbours planning domain.

  Grid assignment problem where:
  - Each cell in an n×m grid gets a number 1-5
  - If a cell has value N>1, it must have neighbors with values 1, 2, ..., N-1
  - Goal: Maximize the sum of all values
  """

  alias AriaPlanner.Domains.Neighbours.Predicates.GridValue

  @doc """
  Creates and registers the neighbours planning domain.
  """
  @spec create_domain() :: {:ok, map()} | {:error, String.t()}
  def create_domain do
    case create_planning_domain() do
      {:ok, domain} ->
        domain = register_actions(domain)
        domain = register_task_methods(domain)
        domain = register_goal_methods(domain)
        {:ok, domain}

      error ->
        error
    end
  end

  @doc """
  Creates the base planning domain structure.
  """
  @spec create_planning_domain() :: {:ok, map()} | {:error, String.t()}
  def create_planning_domain do
    {:ok,
     %{
       type: "neighbours",
       predicates: ["grid_value"],
       actions: [],
       methods: [],
       goal_methods: [],
       created_at: DateTime.utc_now()
     }}
  end

  defp register_actions(domain) do
    actions = [
      %{
        name: "a_assign_value",
        arity: 3,
        preconditions: [
          "grid_value[row, col] == 0 or grid_value[row, col] == undefined",
          "value >= 1",
          "value <= 5",
          "if value > 1 then has_neighbors_with_values(row, col, 1..value-1) else true"
        ],
        effects: ["grid_value[row, col] = value"]
      }
    ]

    Map.put(domain, :actions, actions)
  end

  defp register_task_methods(domain) do
    methods = [
      %{
        name: "maximize_grid",
        type: "task",
        arity: 1,
        decomposition: "assign values to maximize grid sum"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "maximize_grid",
        type: "multigoal",
        arity: 1,
        predicate: nil,
        decomposition: "assign values to maximize grid sum (goal-based)"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end

  @doc """
  Initializes the neighbours state with given grid dimensions.
  """
  @spec initialize_state(n :: integer(), m :: integer()) :: {:ok, map()} | {:error, String.t()}
  def initialize_state(n, m) when n > 0 and m > 0 do
    try do
      grid =
        for i <- 1..n, j <- 1..m, into: %{} do
          {{i, j}, 0}
        end

      state = %{
        n: n,
        m: m,
        grid: grid
      }

      {:ok, state}
    rescue
      e ->
        {:error, "Failed to initialize state: #{inspect(e)}"}
    end
  end

  @doc """
  Gets neighbors of a cell (cells sharing an edge).
  """
  @spec get_neighbors(state :: map(), row :: integer(), col :: integer()) :: [{integer(), integer()}]
  def get_neighbors(state, row, col) do
    n = state.n
    m = state.m

    [
      {row - 1, col},
      {row + 1, col},
      {row, col - 1},
      {row, col + 1}
    ]
    |> Enum.filter(fn {r, c} ->
      r >= 1 and r <= n and c >= 1 and c <= m
    end)
  end

  @doc """
  Checks if a cell has neighbors with all required values.
  """
  @spec has_neighbors_with_values(
          state :: map(),
          row :: integer(),
          col :: integer(),
          required_values :: Range.t() | list()
        ) ::
          boolean()
  def has_neighbors_with_values(state, row, col, required_values) do
    # Handle ranges: check if it's a valid non-empty range
    values_list =
      case required_values do
        first..last//step = range ->
          # For ranges, check if it's effectively empty
          # A range like 1..0//-1 has first=1, last=0, step=-1
          # This is a valid descending range, but if first > last with negative step,
          # it's a "backwards" range that should be treated as "no requirements"
          # If step is negative and first > last, it's a backwards descending range (treat as empty)
          # If step is positive and first > last, it's an invalid/empty range
          # If step is negative and first < last, it's an invalid/empty range
          if (step < 0 and first > last) or (step > 0 and first > last) or (step < 0 and first < last) do
            # Empty/invalid range = no requirements
            []
          else
            Enum.to_list(range)
          end

        _ ->
          # Not a range, treat as list
          required_values
      end

    # Empty list means no requirements, so it's always true
    if Enum.empty?(values_list) do
      true
    else
      neighbors = get_neighbors(state, row, col)
      neighbor_values = Enum.map(neighbors, fn {r, c} -> GridValue.get(state, r, c) end)

      Enum.all?(values_list, fn value ->
        value in neighbor_values
      end)
    end
  end

  @doc """
  Calculates the objective value (sum of all grid values).
  """
  @spec calculate_objective(state :: map()) :: integer()
  def calculate_objective(state) do
    state.grid
    |> Map.values()
    |> Enum.sum()
  end

  @doc """
  Checks if all cells are assigned.
  """
  @spec is_complete?(state :: map()) :: boolean()
  def is_complete?(state) do
    state.grid
    |> Map.values()
    |> Enum.all?(fn value -> value > 0 end)
  end

  @doc """
  Parses a MiniZinc .dzn data file.
  """
  @spec parse_dzn_file(path :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse_dzn_file(path) do
    case File.read(path) do
      {:ok, content} ->
        params = %{}
        params = parse_dzn_line(content, "n", params, :n)
        params = parse_dzn_line(content, "m", params, :m)
        {:ok, params}

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  defp parse_dzn_line(content, key, params, param_key) do
    regex = ~r/#{key}\s*=\s*(\d+);/

    case Regex.run(regex, content) do
      [_, value] ->
        Map.put(params, param_key, String.to_integer(value))

      nil ->
        params
    end
  end
end
