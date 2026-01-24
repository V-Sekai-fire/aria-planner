# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.ActivateGraph do
  @moduledoc """
  Command: c_activate_graph(graph_id)

  Activates a behavior graph.

  Preconditions:
  - None (graph can always be activated)

  Effects:
  - Graph is marked as active
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.GraphActive

  @spec c_activate_graph(state :: map(), graph_id :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def c_activate_graph(state, graph_id) do
    # Activate the graph
    state = GraphActive.activate(state)

    # Store graph_id for reference
    state = Map.put(state, {:active_graph, graph_id}, true)

    {:ok, state}
  end
end
