# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Planner.LazyRefinement do
  @moduledoc """
  Implements the lazy plan refinement logic, executing actions incrementally
  and handling blacklisting, similar to IPyHOP's planning mechanism.
  """

  require Logger

  alias AriaCore.Plan
  alias AriaCore.Planner.State
  alias AriaCore.Planner.Methods
  alias AriaCore.Planner.Actions
  # alias AriaCore.Planner.MultiGoal # Removed unused alias
  # alias __MODULE__, as: LazyRefinement # Removed unused alias

  alias AriaCore.Planner.LazyRefinement.GraphOperations
  alias AriaCore.Planner.LazyRefinement.Backtracking
  alias AriaCore.Planner.LazyRefinement.NodeUtils

  # This function will be the core of the lazy refinement process.
  # It will take a plan, an initial state, and other options, and
  # incrementally execute actions, updating the plan's execution status.
  @spec run_lazy_refineahead(
          domain_spec :: %{methods: Methods.t(), actions: Actions.t(), initial_tasks: list()},
          initial_state_params :: %{
            current_time: DateTime.t(),
            timeline: map(),
            entity_capabilities: map(),
            facts: map()
          },
          plan :: Plan.t(),
          opts :: keyword()
        ) :: {:ok, Plan.t()} | {:error, String.t()}
  # Fix unused opts
  def run_lazy_refineahead(domain_spec, initial_state_params, plan, _opts \\ []) do
    Logger.info("Starting lazy refinement for plan #{plan.id}")

    # Initialize planning state using the new State.new/4 function
    current_state =
      State.new(
        initial_state_params.current_time,
        initial_state_params.timeline,
        initial_state_params.entity_capabilities,
        initial_state_params.facts
      )

    # Node 0 is the root
    solution_graph = %{0 => %{info: {:root}, type: :D, status: :NA, successors: []}}
    blacklisted_commands = MapSet.new()

    # Extract methods, actions, and initial tasks from domain_spec
    methods = domain_spec.methods
    actions = domain_spec.actions
    initial_tasks = domain_spec.initial_tasks

    # Add initial tasks to the solution graph
    # Fix _id
    id = 0
    parent_node_id = 0
    # Fix _id
    {id, solution_graph} =
      GraphOperations.add_nodes_and_edges(id, parent_node_id, initial_tasks, solution_graph, methods, actions)

    updated_plan =
      plan
      |> Map.put(:execution_status, "executing")
      |> Map.put(:execution_started_at, DateTime.utc_now())

    # Start the planning loop
    # Fix _id
    {final_state, final_solution_graph, _final_blacklisted_commands, iterations} =
      planning_loop(id, parent_node_id, current_state, solution_graph, blacklisted_commands, methods, actions)

    # After execution, update plan status
    # Removed redundant assignment to _final_plan

    # Extract the solution plan (sequence of actions)
    solution_plan = GraphOperations.extract_solution_plan(final_solution_graph)

    # Calculate total planning duration
    planning_duration_ms =
      Enum.reduce(Map.values(final_solution_graph), 0, fn node, acc ->
        if node.type == :A and Map.has_key?(node, :duration) do
          acc + node.duration
        else
          acc
        end
      end)

    # Fix unused final_plan
    final_plan =
      updated_plan
      |> Map.put(:execution_status, "completed")
      |> Map.put(:execution_completed_at, DateTime.utc_now())
      # Store the final graph
      |> Map.put(:solution_graph_data, final_solution_graph)
      # Store final state snapshot
      |> Map.put(:planner_state_snapshot, Jason.encode!(final_state))
      # Store the extracted plan
      |> Map.put(:solution_plan, Jason.encode!(solution_plan))
      # Store the total duration
      |> Map.put(:planning_duration_ms, planning_duration_ms)

    Logger.info(
      "Completed lazy refinement for plan #{plan.id} in #{iterations} iterations. Total duration: #{planning_duration_ms}ms."
    )

    # Return the final plan
    {:ok, final_plan}
  end

  # Helper function to simulate IPyHOP's _planning logic
  # This will be expanded to handle tasks, actions, goals, multigoals,
  # backtracking, and state updates.
  # Fix _id
  defp planning_loop(id, parent_node_id, current_state, solution_graph, blacklisted_commands, methods, actions) do
    # Fix _iter
    iter = 0
    # Fix _id, _iter
    planning_loop_recursive(
      id,
      parent_node_id,
      current_state,
      solution_graph,
      blacklisted_commands,
      methods,
      actions,
      iter
    )
  end

  # Fix _id, _iter
  defp planning_loop_recursive(
         id,
         parent_node_id,
         current_state,
         solution_graph,
         blacklisted_commands,
         methods,
         actions,
         iter
       ) do
    # Find the first Open node (BFS-like)
    Logger.info("planning_loop_recursive: id=#{id}, parent_node_id=#{parent_node_id}, iter=#{iter}")

    case GraphOperations.find_open_node(solution_graph, parent_node_id) do
      {:ok, curr_node_id} ->
        Logger.info("Iteration #{iter}, Refining node #{inspect(Map.get(solution_graph, curr_node_id).info)}")
        curr_node = Map.get(solution_graph, curr_node_id)

        # Save current state if first visit
        solution_graph =
          if Map.has_key?(curr_node, :state) and is_nil(curr_node.state) do
            Map.put(solution_graph, curr_node_id, %{curr_node | state: current_state})
          else
            solution_graph
          end

        # Restore state if backtracking
        current_state =
          if Map.has_key?(curr_node, :state) and not is_nil(curr_node.state) do
            curr_node.state
          else
            current_state
          end

        case curr_node.type do
          # Task
          :T ->
            case Enum.find_value(curr_node.available_methods, fn method ->
                   subtasks = apply(method, [current_state | Tuple.to_list(curr_node.info)])
                   if subtasks != nil, do: {method, subtasks}, else: nil
                 end) do
              {selected_method, subtasks} ->
                Logger.info(
                  "Task #{inspect(curr_node.info)} successfully refined with method #{inspect(selected_method)}"
                )

                solution_graph =
                  Map.put(solution_graph, curr_node_id, %{curr_node | status: :C, selected_method: selected_method})

                # Fix _id
                {new_id, new_solution_graph} =
                  GraphOperations.add_nodes_and_edges(id, curr_node_id, subtasks, solution_graph, methods, actions)

                # Fix _id, _iter
                planning_loop_recursive(
                  new_id,
                  curr_node_id,
                  current_state,
                  new_solution_graph,
                  blacklisted_commands,
                  methods,
                  actions,
                  iter + 1
                )

              _ ->
                Logger.warning("Task #{inspect(curr_node.info)} refinement failed. Backtracking.")

                {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state, new_blacklisted_commands} =
                  Backtracking.backtrack(
                    solution_graph,
                    parent_node_id,
                    curr_node_id,
                    current_state,
                    blacklisted_commands
                  )

                # Fix _id, _iter
                planning_loop_recursive(
                  id,
                  new_parent_node_id,
                  new_current_state,
                  new_solution_graph,
                  new_blacklisted_commands,
                  methods,
                  actions,
                  iter + 1
                )
            end

          # Action
          :A ->
            if MapSet.member?(blacklisted_commands, curr_node.info) do
              Logger.warning("Action #{inspect(curr_node.info)} is blacklisted. Backtracking.")

              {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state, new_blacklisted_commands} =
                Backtracking.backtrack(
                  solution_graph,
                  parent_node_id,
                  curr_node_id,
                  current_state,
                  blacklisted_commands
                )

              # Fix _id, _iter
              planning_loop_recursive(
                id,
                new_parent_node_id,
                new_current_state,
                new_solution_graph,
                new_blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            else
              # Check entity capabilities before executing action
              # Assuming action functions will check for required capabilities within their logic
              # For now, directly call the action
              case apply(curr_node.action, [current_state | Tuple.to_list(curr_node.info)]) do
                {:ok, _new_state, duration} ->
                  Logger.info("Action #{inspect(curr_node.info)} successful with duration #{duration}ms.")
                  # Update current_time in state
                  new_current_time = DateTime.add(current_state.current_time, duration, :millisecond)
                  updated_state = %{current_state | current_time: new_current_time}

                  solution_graph =
                    Map.put(solution_graph, curr_node_id, %{
                      curr_node
                      | status: :C,
                        start_time: current_state.current_time,
                        end_time: new_current_time,
                        duration: duration
                    })

                  # Fix _id, _iter
                  planning_loop_recursive(
                    id,
                    parent_node_id,
                    updated_state,
                    solution_graph,
                    blacklisted_commands,
                    methods,
                    actions,
                    iter + 1
                  )

                {:error, reason} ->
                  Logger.warning("Action #{inspect(curr_node.info)} failed: #{reason}. Backtracking.")

                  {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state,
                   new_blacklisted_commands} =
                    Backtracking.backtrack(
                      solution_graph,
                      parent_node_id,
                      curr_node_id,
                      current_state,
                      blacklisted_commands
                    )

                  # Fix _id, _iter
                  planning_loop_recursive(
                    id,
                    new_parent_node_id,
                    new_current_state,
                    new_solution_graph,
                    new_blacklisted_commands,
                    methods,
                    actions,
                    iter + 1
                  )
              end
            end

          # Goal
          :G ->
            # Support new goal format: {predicate_table, [subject_id, desired_val]}
            # and legacy format: {subject_id, predicate_table, desired_val}
            {is_achieved, goal_info} =
              case curr_node.info do
                {predicate_table, args} when is_list(args) ->
                  [subject_id, desired_val] = args
                  achieved = State.get_fact_by_predicate(current_state, predicate_table, subject_id) == desired_val
                  {achieved, {predicate_table, args}}

                {subject_id, predicate_table, desired_val} when is_binary(subject_id) or is_atom(subject_id) ->
                  # Legacy format support
                  achieved = State.get_fact(current_state, subject_id, predicate_table) == desired_val
                  {achieved, {subject_id, predicate_table, desired_val}}

                _ ->
                  # Unknown format, treat as not achieved
                  {false, curr_node.info}
              end

            if is_achieved do
              Logger.info("Goal #{inspect(goal_info)} already achieved.")
              solution_graph = Map.put(solution_graph, curr_node_id, %{curr_node | status: :C})
              # Add empty subgoals for verification # Fix _id
              {new_id, new_solution_graph} =
                GraphOperations.add_nodes_and_edges(id, curr_node_id, [], solution_graph, methods, actions)

              # Fix _id, _iter
              planning_loop_recursive(
                new_id,
                curr_node_id,
                current_state,
                new_solution_graph,
                blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            else
              case Enum.find_value(curr_node.available_methods, fn method ->
                     subgoals = apply(method, [current_state | Tuple.to_list(curr_node.info)])
                     if subgoals != nil, do: {method, subgoals}, else: nil
                   end) do
                {selected_method, subgoals} ->
                  Logger.info(
                    "Goal #{inspect(curr_node.info)} successfully refined with method #{inspect(selected_method)}"
                  )

                  solution_graph =
                    Map.put(solution_graph, curr_node_id, %{curr_node | status: :C, selected_method: selected_method})

                  # Fix _id
                  {new_id, new_solution_graph} =
                    GraphOperations.add_nodes_and_edges(id, curr_node_id, subgoals, solution_graph, methods, actions)

                  # Fix _id, _iter
                  planning_loop_recursive(
                    new_id,
                    curr_node_id,
                    current_state,
                    new_solution_graph,
                    blacklisted_commands,
                    methods,
                    actions,
                    iter + 1
                  )

                _ ->
                  Logger.warning("Goal #{inspect(curr_node.info)} refinement failed. Backtracking.")

                  {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state,
                   new_blacklisted_commands} =
                    Backtracking.backtrack(
                      solution_graph,
                      parent_node_id,
                      curr_node_id,
                      current_state,
                      blacklisted_commands
                    )

                  # Fix _id, _iter
                  planning_loop_recursive(
                    id,
                    new_parent_node_id,
                    new_current_state,
                    new_solution_graph,
                    new_blacklisted_commands,
                    methods,
                    actions,
                    iter + 1
                  )
              end
            end

          # MultiGoal
          :M ->
            if NodeUtils.goals_not_achieved(curr_node.info, current_state) == [] do
              Logger.info("MultiGoal #{inspect(curr_node.info)} already achieved.")
              solution_graph = Map.put(solution_graph, curr_node_id, %{curr_node | status: :C})
              # Add empty subgoals for verification # Fix _id
              {new_id, new_solution_graph} =
                GraphOperations.add_nodes_and_edges(id, curr_node_id, [], solution_graph, methods, actions)

              # Fix _id, _iter
              planning_loop_recursive(
                new_id,
                curr_node_id,
                current_state,
                new_solution_graph,
                blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            else
              case Enum.find_value(curr_node.available_methods, fn method ->
                     subgoals = apply(method, [current_state, curr_node.info])
                     if subgoals != nil, do: {method, subgoals}, else: nil
                   end) do
                {selected_method, subgoals} ->
                  Logger.info(
                    "MultiGoal #{inspect(curr_node.info)} successfully refined with method #{inspect(selected_method)}"
                  )

                  solution_graph =
                    Map.put(solution_graph, curr_node_id, %{curr_node | status: :C, selected_method: selected_method})

                  # Fix _id
                  {new_id, new_solution_graph} =
                    GraphOperations.add_nodes_and_edges(id, curr_node_id, subgoals, solution_graph, methods, actions)

                  # Fix _id, _iter
                  planning_loop_recursive(
                    new_id,
                    curr_node_id,
                    current_state,
                    new_solution_graph,
                    blacklisted_commands,
                    methods,
                    actions,
                    iter + 1
                  )

                _ ->
                  Logger.warning("MultiGoal #{inspect(curr_node.info)} refinement failed. Backtracking.")

                  {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state,
                   new_blacklisted_commands} =
                    Backtracking.backtrack(
                      solution_graph,
                      parent_node_id,
                      curr_node_id,
                      current_state,
                      blacklisted_commands
                    )

                  # Fix _id, _iter
                  planning_loop_recursive(
                    id,
                    new_parent_node_id,
                    new_current_state,
                    new_solution_graph,
                    new_blacklisted_commands,
                    methods,
                    actions,
                    iter + 1
                  )
              end
            end

          # Verify Goal
          :VG ->
            goal_node = Map.get(solution_graph, parent_node_id)
            # Support new goal format: {predicate_table, [subject_id, desired_val]}
            # and legacy format: {subject_id, predicate_table, desired_val}
            is_achieved =
              case goal_node.info do
                {predicate_table, args} when is_list(args) ->
                  [subject_id, desired_val] = args
                  State.get_fact_by_predicate(current_state, predicate_table, subject_id) == desired_val

                {subject_id, predicate_table, desired_val} when is_binary(subject_id) or is_atom(subject_id) ->
                  # Legacy format support
                  State.get_fact(current_state, subject_id, predicate_table) == desired_val

                _ ->
                  # Unknown format, treat as not achieved
                  false
              end

            if is_achieved do
              Logger.info("Goal #{inspect(goal_node.info)} verified successfully.")
              solution_graph = Map.put(solution_graph, curr_node_id, %{curr_node | status: :C})
              # Fix _id, _iter
              planning_loop_recursive(
                id,
                parent_node_id,
                current_state,
                solution_graph,
                blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            else
              Logger.warning("Goal #{inspect(goal_node.info)} verification failed. Backtracking.")

              {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state, new_blacklisted_commands} =
                Backtracking.backtrack(
                  solution_graph,
                  parent_node_id,
                  curr_node_id,
                  current_state,
                  blacklisted_commands
                )

              # Fix _id, _iter
              planning_loop_recursive(
                id,
                new_parent_node_id,
                new_current_state,
                new_solution_graph,
                new_blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            end

          # Verify MultiGoal
          :VM ->
            multigoal_node = Map.get(solution_graph, parent_node_id)

            if NodeUtils.goals_not_achieved(multigoal_node.info, current_state) == [] do
              Logger.info("MultiGoal #{inspect(multigoal_node.info)} verified successfully.")
              solution_graph = Map.put(solution_graph, curr_node_id, %{curr_node | status: :C})
              # Fix _id, _iter
              planning_loop_recursive(
                id,
                parent_node_id,
                current_state,
                solution_graph,
                blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            else
              Logger.warning("MultiGoal #{inspect(multigoal_node.info)} verification failed. Backtracking.")

              {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state, new_blacklisted_commands} =
                Backtracking.backtrack(
                  solution_graph,
                  parent_node_id,
                  curr_node_id,
                  current_state,
                  blacklisted_commands
                )

              # Fix _id, _iter
              planning_loop_recursive(
                id,
                new_parent_node_id,
                new_current_state,
                new_solution_graph,
                new_blacklisted_commands,
                methods,
                actions,
                iter + 1
              )
            end

          # Other node types (D)
          _ ->
            # For now, just fail and backtrack
            {new_parent_node_id, _new_curr_node_id, new_solution_graph, new_current_state, new_blacklisted_commands} =
              Backtracking.backtrack(solution_graph, parent_node_id, curr_node_id, current_state, blacklisted_commands)

            # Fix _id, _iter
            planning_loop_recursive(
              id,
              new_parent_node_id,
              new_current_state,
              new_solution_graph,
              new_blacklisted_commands,
              methods,
              actions,
              iter + 1
            )
        end

      :no_open_node ->
        # If no open node found, try to move up the tree (backtrack to parent's parent)
        case Map.get(solution_graph, parent_node_id) do
          # If parent is root, planning complete
          %{type: :D} ->
            # Fix _iter
            {current_state, solution_graph, blacklisted_commands, iter}

          _ ->
            # Move to predecessor of parent_node_id
            # This assumes a simple tree structure where each node has one predecessor
            new_parent_node_id = GraphOperations.find_predecessor(solution_graph, parent_node_id)
            # Fix _id, _iter
            planning_loop_recursive(
              id,
              new_parent_node_id,
              current_state,
              solution_graph,
              blacklisted_commands,
              methods,
              actions,
              iter + 1
            )
        end
    end
  end

  # Helper function for blacklisting commands
  def blacklist_command(blacklisted_commands, command) do
    MapSet.put(blacklisted_commands, command)
  end
end
