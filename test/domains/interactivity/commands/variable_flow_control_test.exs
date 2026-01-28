# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.VariableFlowControlTest do
  @moduledoc """
  Tests for variable and flow control operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    FlowBranch,
    VariableGet
  }

  describe "variable operations" do
    test "get variable value", %{state: state} do
      state = VariableValue.set(state, "my_var", 42.0)
      state = SocketValue.set(state, "node1", "a", "my_var")

      {:ok, result_state} = VariableGet.c_variable_get(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 42.0
    end
  end

  describe "flow control operations" do
    test "flow branch", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)

      {:ok, result_state} = FlowBranch.c_flow_branch(state, "node1", "a", "b", "value")

      assert NodeExecuted.get(result_state, "node1") == true
    end
  end
end
