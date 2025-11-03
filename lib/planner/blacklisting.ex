# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Planner.Blacklisting do
  @moduledoc """
  Blacklisting functionality for commands and methods in the HTN planner.

  This module provides functions to blacklist commands and methods that have failed
  during execution, allowing the planner to try alternative approaches.
  """

  @type blacklist_state :: %{
          blacklisted_commands: MapSet.t(),
          blacklisted_methods: MapSet.t()
        }

  @doc """
  Creates a new empty blacklist state.
  """
  @spec new() :: blacklist_state()
  def new do
    %{
      blacklisted_commands: MapSet.new(),
      blacklisted_methods: MapSet.new()
    }
  end

  @doc """
  Blacklists a command by adding it to the blacklist.

  ## Parameters
  - `blacklist_state`: The current blacklist state
  - `command`: The command tuple {action_name, args} to blacklist

  ## Returns
  Updated blacklist state with the command added
  """
  @spec blacklist_command(blacklist_state(), {atom() | String.t(), list()}) :: blacklist_state()
  def blacklist_command(blacklist_state, {action_name, args}) do
    command_key = {action_name, args}
    %{blacklist_state | blacklisted_commands: MapSet.put(blacklist_state.blacklisted_commands, command_key)}
  end

  @doc """
  Checks if a command is blacklisted.

  ## Parameters
  - `blacklist_state`: The current blacklist state
  - `command`: The command tuple {action_name, args} to check

  ## Returns
  `true` if the command is blacklisted, `false` otherwise
  """
  @spec command_blacklisted?(blacklist_state(), {atom() | String.t(), list()}) :: boolean()
  def command_blacklisted?(blacklist_state, {action_name, args}) do
    command_key = {action_name, args}
    MapSet.member?(blacklist_state.blacklisted_commands, command_key)
  end

  @doc """
  Blacklists a method by adding it to the blacklist.

  ## Parameters
  - `blacklist_state`: The current blacklist state
  - `method_name`: The method name to blacklist

  ## Returns
  Updated blacklist state with the method added
  """
  @spec blacklist_method(blacklist_state(), String.t()) :: blacklist_state()
  def blacklist_method(blacklist_state, method_name) do
    %{blacklist_state | blacklisted_methods: MapSet.put(blacklist_state.blacklisted_methods, method_name)}
  end

  @doc """
  Checks if a method is blacklisted.

  ## Parameters
  - `blacklist_state`: The current blacklist state
  - `method_name`: The method name to check

  ## Returns
  `true` if the method is blacklisted, `false` otherwise
  """
  @spec method_blacklisted?(blacklist_state(), String.t()) :: boolean()
  def method_blacklisted?(blacklist_state, method_name) do
    MapSet.member?(blacklist_state.blacklisted_methods, method_name)
  end

  @doc """
  Clears all blacklisted commands and methods.

  ## Parameters
  - `blacklist_state`: The current blacklist state

  ## Returns
  New blacklist state with empty sets
  """
  @spec clear(blacklist_state()) :: blacklist_state()
  def clear(_blacklist_state) do
    new()
  end

  @doc """
  Gets the count of blacklisted commands.

  ## Parameters
  - `blacklist_state`: The current blacklist state

  ## Returns
  Number of blacklisted commands
  """
  @spec blacklisted_command_count(blacklist_state()) :: non_neg_integer()
  def blacklisted_command_count(blacklist_state) do
    MapSet.size(blacklist_state.blacklisted_commands)
  end

  @doc """
  Gets the count of blacklisted methods.

  ## Parameters
  - `blacklist_state`: The current blacklist state

  ## Returns
  Number of blacklisted methods
  """
  @spec blacklisted_method_count(blacklist_state()) :: non_neg_integer()
  def blacklisted_method_count(blacklist_state) do
    MapSet.size(blacklist_state.blacklisted_methods)
  end
end
