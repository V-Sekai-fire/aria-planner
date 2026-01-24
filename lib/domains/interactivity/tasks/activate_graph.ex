# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Tasks.ActivateGraph do
  @moduledoc """
  Task: t_activate_graph(graph_id)

  Activates a behavior graph, making it ready for execution.
  When a glTF asset contains a behavior graph, animations are controlled by the graph.

  This task decomposes into:
  - Set graph_active predicate
  - Initialize custom variables
  """

  @doc """
  Task method for activating a behavior graph.

  Decomposes into:
  - Activate graph command
  - Initialize variables task
  """
  @spec t_activate_graph(graph_id :: String.t()) :: list()
  def t_activate_graph(graph_id) do
    [
      {"c_activate_graph", graph_id},
      {"t_initialize_variables", graph_id}
    ]
  end
end
