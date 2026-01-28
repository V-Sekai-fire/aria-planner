# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.TypeConversionTest do
  @moduledoc """
  Tests for type conversion operations in the Interactivity domain.
  """

  use AriaPlanner.Domains.Interactivity.Commands.TestHelper

  alias AriaPlanner.Domains.Interactivity.Commands.{
    TypeBoolToFloat,
    TypeBoolToInt,
    TypeFloatToBool,
    TypeFloatToInt,
    TypeIntToBool,
    TypeIntToFloat
  }

  describe "type conversions" do
    test "bool to float", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)

      {:ok, result_state} = TypeBoolToFloat.c_type_bool_to_float(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 1.0
    end

    test "float to int", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 3.7)

      {:ok, result_state} = TypeFloatToInt.c_type_float_to_int(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 3
    end

    test "int to float", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 42)

      {:ok, result_state} = TypeIntToFloat.c_type_int_to_float(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 42.0
    end

    test "bool to int", %{state: state} do
      state = SocketValue.set(state, "node1", "a", true)

      {:ok, result_state} = TypeBoolToInt.c_type_bool_to_int(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == 1
    end

    test "float to bool true", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 1.5)

      {:ok, result_state} = TypeFloatToBool.c_type_float_to_bool(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "float to bool false", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0.0)

      {:ok, result_state} = TypeFloatToBool.c_type_float_to_bool(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == false
    end

    test "int to bool true", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 42)

      {:ok, result_state} = TypeIntToBool.c_type_int_to_bool(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == true
    end

    test "int to bool false", %{state: state} do
      state = SocketValue.set(state, "node1", "a", 0)

      {:ok, result_state} = TypeIntToBool.c_type_int_to_bool(state, "node1", "a", "value")

      assert NodeExecuted.get(result_state, "node1") == true
      result = SocketValue.get(result_state, "node1", "value")
      assert result == false
    end
  end
end
