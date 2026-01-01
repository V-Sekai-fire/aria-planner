# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#

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
    personas: :aria_planner_personas,
    facts_allocentric: :aria_planner_facts_allocentric,
    predicates: :aria_planner_predicates,
    planning_domains: :aria_planner_planning_domains,
    locations: :aria_planner_locations,
    items: :aria_planner_items
  }

  # Initialize tables on module load
  def init do
    for {_name, table} <- @tables do
      case :ets.whereis(table) do
        :undefined ->
          :ets.new(table, [:named_table, :set, :public])

        _ ->
          :ok
      end
    end

    :ok
  end

  def start_link do
    # Initialize tables
    init()
    {:ok, self()}
  end

  def insert(table_name, id, data) when is_atom(table_name) and is_binary(id) and is_map(data) do
    table = Map.get(@tables, table_name)

    if table do
      try do
        :ets.insert(table, {id, data})
        {:ok, data}
      rescue
        e -> {:error, "ETS insert failed: #{inspect(e)}"}
      catch
        :exit, reason -> {:error, "ETS insert exit: #{inspect(reason)}"}
        :throw, reason -> {:error, "ETS insert throw: #{inspect(reason)}"}
      end
    else
      {:error, :unknown_table}
    end
  end

  def insert(_table_name, _id, _data) do
    {:error, :invalid_input}
  end

  def get(table_name, id) when is_atom(table_name) and is_binary(id) do
    table = Map.get(@tables, table_name)

    if table do
      try do
        case :ets.lookup(table, id) do
          [{^id, data}] -> {:ok, data}
          [] -> {:error, :not_found}
        end
      rescue
        e -> {:error, "ETS lookup failed: #{inspect(e)}"}
      catch
        :exit, reason -> {:error, "ETS lookup exit: #{inspect(reason)}"}
        :throw, reason -> {:error, "ETS lookup throw: #{inspect(reason)}"}
      end
    else
      {:error, :unknown_table}
    end
  end

  def get(_table_name, _id) do
    {:error, :invalid_input}
  end

  def all(table_name) when is_atom(table_name) do
    table = Map.get(@tables, table_name)

    if table do
      try do
        :ets.tab2list(table)
        |> Enum.map(fn {_id, data} -> data end)
      rescue
        e -> {:error, "ETS tab2list failed: #{inspect(e)}"}
      catch
        :exit, reason -> {:error, "ETS tab2list exit: #{inspect(reason)}"}
        :throw, reason -> {:error, "ETS tab2list throw: #{inspect(reason)}"}
      end
    else
      []
    end
  end

  def all(_table_name) do
    []
  end

  def delete(table_name, id) when is_atom(table_name) and is_binary(id) do
    table = Map.get(@tables, table_name)

    if table do
      try do
        :ets.delete(table, id)
        :ok
      rescue
        e -> {:error, "ETS delete failed: #{inspect(e)}"}
      catch
        :exit, reason -> {:error, "ETS delete exit: #{inspect(reason)}"}
        :throw, reason -> {:error, "ETS delete throw: #{inspect(reason)}"}
      end
    else
      {:error, :unknown_table}
    end
  end

  def delete(_table_name, _id) do
    {:error, :invalid_input}
  end

  def clear(table_name) when is_atom(table_name) do
    table = Map.get(@tables, table_name)

    if table do
      try do
        :ets.delete_all_objects(table)
        :ok
      rescue
        e -> {:error, "ETS clear failed: #{inspect(e)}"}
      catch
        :exit, reason -> {:error, "ETS clear exit: #{inspect(reason)}"}
        :throw, reason -> {:error, "ETS clear throw: #{inspect(reason)}"}
      end
    else
      {:error, :unknown_table}
    end
  end

  def clear(_table_name) do
    {:error, :invalid_input}
  end

  def clear_all do
    for {_name, table} <- @tables do
      :ets.delete_all_objects(table)
    end

    :ok
  end
end
