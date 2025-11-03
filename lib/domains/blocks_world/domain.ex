# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

  defmodule AriaPlanner.Domains.BlocksWorld do
  @moduledoc """
  Blocks World planning domain.

  This module registers and manages the blocks world domain with the MCP infrastructure.
  It provides both task-based and goal-based planning variants that can be mixed and matched.

  The domain includes:
  - Predicates: pos, clear, holding
  - Actions: a_pickup, a_unstack, a_putdown, a_stack
  - Methods: move_blocks, move_one, get, put (task-based)
  - Goal Methods: gm_move1, gm_get, gm_put (goal-based)
  """

  # Aliases for commands, predicates, and tasks
  require AriaPlanner.Domains.BlocksWorld.Commands.Pickup
  require AriaPlanner.Domains.BlocksWorld.Commands.Putdown
  require AriaPlanner.Domains.BlocksWorld.Commands.Stack
  require AriaPlanner.Domains.BlocksWorld.Commands.Unstack
  require AriaPlanner.Domains.BlocksWorld.Commands.CreateAtom
  require AriaPlanner.Domains.BlocksWorld.Commands.CreatePos
  require AriaPlanner.Domains.BlocksWorld.Commands.CreateClear
  require AriaPlanner.Domains.BlocksWorld.Commands.CreateHolding

  alias AriaPlanner.Domains.BlocksWorld.Predicates.Pos
  alias AriaPlanner.Domains.BlocksWorld.Predicates.Clear
  alias AriaPlanner.Domains.BlocksWorld.Predicates.Holding

  alias AriaPlanner.Repo

  @doc """
  Creates and registers the blocks world planning domain.

  This function sets up the domain with all actions, methods, and goal methods.
  """
  @spec create_domain() :: {:ok, map()} | {:error, String.t()}
  def create_domain do
    # Create the domain
    case create_planning_domain() do
      {:ok, domain} ->
        # Register actions
        domain = register_actions(domain)
        # Register task-based methods
        domain = register_task_methods(domain)
        # Register goal-based methods
        domain = register_goal_methods(domain)
        {:ok, domain}

      error ->
        error
    end
  end

  @doc """
  Creates the base planning domain structure.
  """
  @spec create_planning_domain() :: {:ok, map()} | {:error, String.t()}
  def create_planning_domain do
    {:ok,
     %{
       type: "blocks_world",
       predicates: ["pos", "clear", "holding"],
       actions: [],
       methods: [],
       goal_methods: [],
       created_at: DateTime.utc_now()
     }}
  end

  defp register_actions(domain) do
    actions = [
      %{
        name: "a_pickup",
        arity: 1,
        preconditions: ["pos[block] == 'table'", "clear[block] == true", "holding['hand'] == false"],
        effects: ["pos[block] = 'hand'", "clear[block] = false", "holding['hand'] = block"]
      },
      %{
        name: "a_unstack",
        arity: 2,
        preconditions: [
          "pos[block] == from_block",
          "from_block != 'table'",
          "clear[block] == true",
          "holding['hand'] == false"
        ],
        effects: [
          "pos[block] = 'hand'",
          "clear[block] = false",
          "holding['hand'] = block",
          "clear[from_block] = true"
        ]
      },
      %{
        name: "a_putdown",
        arity: 1,
        preconditions: ["pos[block] == 'hand'"],
        effects: ["pos[block] = 'table'", "clear[block] = true", "holding['hand'] = false"]
      },
      %{
        name: "a_stack",
        arity: 2,
        preconditions: ["pos[block] == 'hand'", "clear[on_block] == true"],
        effects: [
          "pos[block] = on_block",
          "clear[block] = true",
          "holding['hand'] = false",
          "clear[on_block] = false"
        ]
      }
    ]

    Map.put(domain, :actions, actions)
  end

  defp register_task_methods(domain) do
    methods = [
      %{
        name: "move_blocks",
        type: "task",
        arity: 1,
        decomposition: "recursive block stacking algorithm"
      },
      %{
        name: "move_one",
        type: "task",
        arity: 2,
        decomposition: "get block and put at destination"
      },
      %{
        name: "get",
        type: "task",
        arity: 1,
        decomposition: "pickup or unstack block"
      },
      %{
        name: "put",
        type: "task",
        arity: 2,
        decomposition: "putdown or stack block"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "move_blocks",
        type: "multigoal",
        arity: 1,
        predicate: nil,
        decomposition: "recursive block stacking for goal-based planning"
      },
      %{
        name: "gm_move1",
        type: "goal",
        arity: 2,
        predicate: "pos",
        decomposition: "move block to destination"
      },
      %{
        name: "gm_get",
        type: "goal",
        arity: 2,
        predicate: "pos",
        decomposition: "get block for goal-based planning"
      },
      %{
        name: "gm_put",
        type: "goal",
        arity: 2,
        predicate: "pos",
        decomposition: "put block for goal-based planning"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end

  @doc """
  Initializes the blocks world state with given blocks.

  Creates initial pos, clear, and holding facts for all blocks.
  """
  @spec initialize_state(blocks :: [String.t()]) :: {:ok, map()} | {:error, String.t()}
  def initialize_state(blocks) when is_list(blocks) do
    alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
    alias AriaPlanner.Repo

    try do
      # Create pos facts (all blocks start on table)
      Enum.each(blocks, fn block ->
        Pos.create(%{entity_id: block, value: "table"})
      end)

      # Create clear facts (all blocks start clear)
      Enum.each(blocks, fn block ->
        Clear.create(%{entity_id: block, value: true})
      end)

      # Create holding fact (hand starts empty)
      Holding.create(%{entity_id: "hand", value: "false"})

      {:ok, %{blocks: blocks, initialized: true}}
    rescue
      e ->
        {:error, "Failed to initialize state: #{inspect(e)}"}
    end
  end

  @doc """
  Gets the current state of all blocks.
  """
  @spec get_state() :: {:ok, map()} | {:error, String.t()}
  def get_state do
    alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
    alias AriaPlanner.Repo

    try do
      pos_facts = Repo.all(Pos)
      clear_facts = Repo.all(Clear)
      holding_facts = Repo.all(Holding)

      state = %{
        pos: Map.new(pos_facts, &{&1.entity_id, &1.value}),
        clear: Map.new(clear_facts, &{&1.entity_id, &1.value}),
        holding: Map.new(holding_facts, &{&1.entity_id, &1.value})
      }

      {:ok, state}
    rescue
      e ->
        {:error, "Failed to get state: #{inspect(e)}"}
    end
  end

  @doc """
  Resets the blocks world state (clears all facts).
  """
  @spec reset_state() :: {:ok, String.t()} | {:error, String.t()}
  def reset_state do
    alias AriaPlanner.Domains.BlocksWorld.Predicates.{Pos, Clear, Holding}
    alias AriaPlanner.Repo

    try do
      Repo.delete_all(Pos)
      Repo.delete_all(Clear)
      Repo.delete_all(Holding)
      {:ok, "State reset successfully"}
    rescue
      e ->
        {:error, "Failed to reset state: #{inspect(e)}"}
    end
  end

  @doc """
  Handles domain-specific commands for BlocksWorld.
  """
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.Pickup{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.Pickup.c_pickup(command.obj)
  end
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.Putdown{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.Putdown.c_putdown(command.obj)
  end
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.Stack{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.Stack.c_stack(command.obj_a, command.obj_b)
  end
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.Unstack{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.Unstack.c_unstack(command.obj_a, command.obj_b)
  end

  # Placeholders for new state creation commands which will be defined next
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.CreateAtom{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.CreateAtom.c_create_atom(command.name)
  end
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.CreatePos{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.CreatePos.c_create_pos(command.x, command.y)
  end
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.CreateClear{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.CreateClear.c_create_clear(command.x)
  end
  def handle_command(%AriaPlanner.Domains.BlocksWorld.Commands.CreateHolding{} = command) do
    AriaPlanner.Domains.BlocksWorld.Commands.CreateHolding.c_create_holding(command.x)
  end

  def handle_command(command) do
    {:error, "Unknown command: #{inspect(command)}"}
  end
end
