defmodule AriaPlanner.Storage.EtsStorage do
  @moduledoc """
  Minimal ETS storage wrapper that forwards directly to :ets.
  This replaces that previous implementation with simple :ets calls.
  """

  @tables [
    :aria_planner_planning_domains,
    :aria_planner_items,
    :aria_planner_personas,
    :aria_planner_locations,
    :aria_planner_plans,
    :aria_planner_predicates,
    :aria_planner_facts_allocentric
  ]

  @spec start_link() :: :ok
  def start_link do
    Enum.each(@tables, fn table ->
      # Create a named public ETS table if it doesn't already exist
      unless :ets.whereis(table) != :undefined do
        :ets.new(table, [:named_table, :public, read_concurrency: true])
      end
    end)

    :ok
  end

  @spec init() :: :ok
  def init do
    start_link()
  end

  @spec insert(atom(), any(), any()) :: {:ok, any()} | {:error, term()}
  def insert(table, key, value) do
    if table in @tables do
      :ets.insert(table, {key, value})
      {:ok, value}
    else
      {:error, :unknown_table}
    end
  end

  @spec get(atom(), any()) :: {:ok, any()} | {:error, term()}
  def get(table, key) do
    if table in @tables do
      case :ets.lookup(table, key) do
        [{^key, value}] -> {:ok, value}
        [] -> {:error, :not_found}
      end
    else
      {:error, :unknown_table}
    end
  end

  @spec all(atom()) :: list(any())
  def all(table) do
    if table in @tables do
      :ets.tab2list(table)
      |> Enum.map(fn {_key, value} -> value end)
    else
      []
    end
  end

  @spec delete(atom(), any()) :: :ok | {:error, term()}
  def delete(table, key) do
    if table in @tables do
      :ets.delete(table, key)
      :ok
    else
      {:error, :unknown_table}
    end
  end

  @spec clear(atom()) :: :ok | {:error, term()}
  def clear(table) do
    if table in @tables do
      :ets.delete_all_objects(table)
      :ok
    else
      {:error, :unknown_table}
    end
  end

  @spec clear_all() :: :ok
  def clear_all do
    Enum.each(@tables, fn table ->
      :ets.delete_all_objects(table)
    end)

    :ok
  end
end