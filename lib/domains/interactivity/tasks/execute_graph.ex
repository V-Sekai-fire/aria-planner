# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Tasks.ExecuteGraph do
  @moduledoc """
  Task: t_execute_graph(graph_id)

  Executes a behavior graph by:
  1. Activating the graph
  2. Executing nodes in topological order (respecting flow dependencies)
  3. Handling custom events and variables

  This task decomposes into:
  - Activate graph
  - Execute node sequence (based on flow dependencies)
  """

  @doc """
  Task method for executing a behavior graph.

  Decomposes into:
  - Activate graph
  - Execute nodes in dependency order
  """
  @spec t_execute_graph(graph_id :: String.t()) :: list()
  def t_execute_graph(graph_id) do
    [
      {"t_activate_graph", graph_id},
      {"t_execute_node_sequence", graph_id}
    ]
  end
end
