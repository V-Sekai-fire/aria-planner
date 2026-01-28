# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.SetVariable do
  @moduledoc """
  Command: c_set_variable(variable_name, value)

  Sets the value of a custom variable.
  Variables retain their values until graph execution terminates.

  Preconditions:
  - Graph must be active
  - Variable must be defined in the graph
  - Value type must match variable type

  Effects:
  - Variable value is updated
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.{
    GraphActive,
    VariableValue
  }

  @spec c_set_variable(state :: map(), variable_name :: String.t(), value :: any()) ::
          {:ok, map()} | {:error, String.t()}
  def c_set_variable(state, variable_name, value) do
    with :ok <- check_graph_active(state),
         :ok <- check_variable_defined(state, variable_name),
         :ok <- check_type_compatibility(state, variable_name, value) do
      # Set variable value
      state = VariableValue.set(state, variable_name, value)

      {:ok, state}
    else
      error -> error
    end
  end

  defp check_graph_active(state) do
    if GraphActive.active?(state) do
      :ok
    else
      {:error, "Graph must be active to set variables"}
    end
  end

  defp check_variable_defined(_state, _variable_name) do
    # Check if variable is defined in the graph
    # Simplified: in practice, we'd check against graph metadata
    :ok
  end

  defp check_type_compatibility(_state, _variable_name, _value) do
    # Simplified: in practice, we'd check value type matches variable type
    :ok
  end
end
