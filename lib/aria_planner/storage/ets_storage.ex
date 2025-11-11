# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Storage.EtsStorage do
  @moduledoc """
  ETS-based storage for all environments.
  Provides a simple in-memory storage layer using ETS tables.
  
  This replaces SQLite database storage with fast in-memory ETS tables.
  All data is stored in memory and will be lost on application restart.
  """

  @tables %{
    plans: :aria_planner_plans,
    entities: :aria_planner_entities,
    predicates: :aria_planner_predicates
  }

  def start_link do
    # Create ETS tables for each schema
    for {_name, table} <- @tables do
      :ets.new(table, [:named_table, :set, :public])
    end

    {:ok, self()}
  end

  def insert(table_name, id, data) do
    table = Map.get(@tables, table_name)
    if table do
      :ets.insert(table, {id, data})
      {:ok, data}
    else
      {:error, :unknown_table}
    end
  end

  def get(table_name, id) do
    table = Map.get(@tables, table_name)
    if table do
      case :ets.lookup(table, id) do
        [{^id, data}] -> {:ok, data}
        [] -> {:error, :not_found}
      end
    else
      {:error, :unknown_table}
    end
  end

  def all(table_name) do
    table = Map.get(@tables, table_name)
    if table do
      :ets.tab2list(table)
      |> Enum.map(fn {_id, data} -> data end)
    else
      []
    end
  end

  def delete(table_name, id) do
    table = Map.get(@tables, table_name)
    if table do
      :ets.delete(table, id)
      :ok
    else
      {:error, :unknown_table}
    end
  end

  def clear(table_name) do
    table = Map.get(@tables, table_name)
    if table do
      :ets.delete_all_objects(table)
      :ok
    else
      {:error, :unknown_table}
    end
  end

  def clear_all do
    for {_name, table} <- @tables do
      :ets.delete_all_objects(table)
    end
    :ok
  end
end

