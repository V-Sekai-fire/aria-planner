# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.TestHelper do
  @moduledoc """
  Shared test helper for interactivity command tests.
  """

  alias AriaPlanner.Domains.Interactivity.Predicates.GraphActive

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: true

      alias AriaPlanner.Domains.Interactivity.Predicates.{
        NodeExecuted,
        SocketValue,
        VariableValue
      }

      setup do
        # Create initial state with active graph
        state = %{}
        state = GraphActive.activate(state)
        {:ok, state: state}
      end
    end
  end
end
