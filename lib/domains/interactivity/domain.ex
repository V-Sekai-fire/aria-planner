# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity do
  @moduledoc """
  glTF Interactivity Extension planning domain.

  This domain models glTF 2.0 Interactivity Extension behavior graphs:
  - Behavior graphs (directed acyclic graphs of nodes)
  - Nodes with operations (domain/operation pattern)
  - Sockets (input/output value sockets, input/output flow sockets)
  - Custom events and variables
  - Node execution and flow control

  Supports PDDL/HDDL interoperability for converting behavior graphs
  to planning domain representations.
  """

  @doc """
  Creates and registers the interactivity planning domain.
  """
  @spec create_domain() :: {:ok, map()} | {:error, String.t()}
  def create_domain do
    case create_planning_domain() do
      {:ok, domain} ->
        domain = register_actions(domain)
        domain = register_task_methods(domain)
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
       type: "interactivity",
       predicates: [
         "node_executed",
         "socket_connected",
         "variable_value",
         "event_triggered",
         "graph_active"
       ],
       actions: [],
       methods: [],
       goal_methods: [],
       created_at: DateTime.utc_now()
     }}
  end

  defp register_actions(domain) do
    # Generate action metadata for all implemented commands
    # This includes all 122+ node operations from the glTF Interactivity Extension
    actions = build_action_list()

    Map.put(domain, :actions, actions)
  end

  defp build_action_list do
    # Core graph operations
    core_actions = [
      %{name: "c_activate_graph", arity: 1, preconditions: [], effects: ["graph_active = true"]},
      %{name: "c_execute_node", arity: 2, preconditions: ["graph_active == true"], effects: ["node_executed = true"]},
      %{
        name: "c_connect_socket",
        arity: 4,
        preconditions: ["graph_active == true"],
        effects: ["socket_connected = true"]
      },
      %{name: "c_set_variable", arity: 2, preconditions: ["graph_active == true"], effects: ["variable_value updated"]}
    ]

    # Math operations (unary: 3 args, binary: 4 args, ternary: 5 args, combine: 4-6 args)
    math_unary = [
      "abs",
      "sign",
      "trunc",
      "floor",
      "ceil",
      "round",
      "fract",
      "neg",
      "saturate",
      "sin",
      "cos",
      "tan",
      "asin",
      "acos",
      "atan",
      "sinh",
      "cosh",
      "tanh",
      "asinh",
      "acosh",
      "atanh",
      "exp",
      "log",
      "log2",
      "log10",
      "sqrt",
      "cbrt",
      "rad",
      "deg",
      "is_nan",
      "is_inf",
      "length",
      "normalize",
      "not"
    ]

    math_binary = [
      "add",
      "sub",
      "mul",
      "div",
      "rem",
      "min",
      "max",
      "clamp",
      "mix",
      "eq",
      "lt",
      "le",
      "gt",
      "ge",
      "pow",
      "dot",
      "cross",
      "atan2",
      "and",
      "or",
      "xor",
      "asr",
      "lsl"
    ]

    math_ternary = ["select", "switch"]
    math_combine = ["combine2", "combine3", "combine4", "combine2x2", "combine3x3", "combine4x4"]
    math_extract = ["extract2", "extract3", "extract4", "extract2x2", "extract3x3", "extract4x4"]
    math_matrix = ["transpose", "determinant", "inverse", "mat_mul", "mat_compose", "mat_decompose"]

    math_quat = [
      "quat_conjugate",
      "quat_mul",
      "quat_angle_between",
      "quat_from_axis_angle",
      "quat_to_axis_angle",
      "quat_from_directions",
      "quat_from_up_forward",
      "quat_slerp"
    ]

    math_transform = ["transform", "rotate_2d", "rotate_3d"]
    math_special = ["random", "clz", "ctz", "popcnt"]

    # Math constants (spec requires math/E, math/Pi, math/Inf, math/NaN - uppercase)
    # Elixir function names must be lowercase, so we use lowercase in function names
    # The operation name in domain should match spec (handled via operation mapping)
    math_constants = ["e", "pi", "inf", "nan"]

    # Math constants (2 args: node_id, value_socket, but registered as 3 for consistency)
    math_actions =
      Enum.map(math_constants, fn op ->
        %{
          name: "c_math_#{op}",
          arity: 3,
          preconditions: ["graph_active == true"],
          effects: ["output computed", "node_executed = true"]
        }
      end) ++
        Enum.map(
          math_unary,
          &%{
            name: "c_math_#{&1}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(
          math_binary,
          &%{
            name: "c_math_#{&1}",
            arity: 4,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(
          math_ternary,
          &%{
            name: "c_math_#{&1}",
            arity: 5,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(math_combine, fn op ->
          arity =
            case op do
              "combine4" -> 6
              "combine3" -> 5
              "combine2" -> 4
              "combine4x4" -> 6
              "combine3x3" -> 5
              "combine2x2" -> 4
            end

          %{
            name: "c_math_#{op}",
            arity: arity,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        end) ++
        Enum.map(
          math_extract,
          &%{
            name: "c_math_#{&1}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(
          math_matrix,
          &%{
            name: "c_math_#{&1}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(
          math_quat,
          &%{
            name: "c_math_#{&1}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(
          math_transform,
          &%{
            name: "c_math_#{&1}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        ) ++
        Enum.map(
          math_special,
          &%{
            name: "c_math_#{&1}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["output computed", "node_executed = true"]
          }
        )

    # Type conversion operations
    type_actions =
      ["bool_to_float", "bool_to_int", "float_to_bool", "float_to_int", "int_to_bool", "int_to_float"]
      |> Enum.map(
        &%{
          name: "c_type_#{&1}",
          arity: 3,
          preconditions: ["graph_active == true"],
          effects: ["output computed", "node_executed = true"]
        }
      )

    # Flow control operations
    flow_actions =
      [
        "branch",
        "sequence",
        "multi_gate",
        "switch",
        "while",
        "for",
        "do_n",
        "wait_all",
        "throttle",
        "set_delay",
        "cancel_delay"
      ]
      |> Enum.map(
        &%{
          name: "c_flow_#{&1}",
          arity: 3,
          preconditions: ["graph_active == true"],
          effects: ["flow activated", "node_executed = true"]
        }
      )

    # Variable and pointer operations
    var_actions =
      ["get", "set", "interpolate"]
      |> Enum.flat_map(fn op ->
        [
          %{
            name: "c_variable_#{op}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["variable accessed", "node_executed = true"]
          },
          %{
            name: "c_pointer_#{op}",
            arity: 3,
            preconditions: ["graph_active == true"],
            effects: ["pointer accessed", "node_executed = true"]
          }
        ]
      end)

    # Animation control
    anim_actions =
      ["start", "stop", "stop_at"]
      |> Enum.map(
        &%{
          name: "c_animation_#{&1}",
          arity: 3,
          preconditions: ["graph_active == true"],
          effects: ["animation controlled", "node_executed = true"]
        }
      )

    # Event operations
    event_actions =
      ["on_start", "on_tick", "receive", "send"]
      |> Enum.map(
        &%{
          name: "c_event_#{&1}",
          arity: 3,
          preconditions: ["graph_active == true"],
          effects: ["event handled", "node_executed = true"]
        }
      )

    # Debug operations
    debug_actions = [
      %{
        name: "c_debug_log",
        arity: 3,
        preconditions: ["graph_active == true"],
        effects: ["log output", "node_executed = true"]
      }
    ]

    core_actions ++
      math_actions ++ type_actions ++ flow_actions ++ var_actions ++ anim_actions ++ event_actions ++ debug_actions
  end

  defp register_task_methods(domain) do
    methods = [
      %{
        name: "t_execute_graph",
        type: "task",
        arity: 1,
        decomposition: "execute behavior graph by activating and running nodes"
      },
      %{
        name: "t_activate_graph",
        type: "task",
        arity: 1,
        decomposition: "activate graph and initialize variables"
      },
      %{
        name: "t_execute_node_sequence",
        type: "task",
        arity: 1,
        decomposition: "execute nodes in topological order"
      }
    ]

    Map.update(domain, :methods, methods, &(&1 ++ methods))
  end

  defp register_goal_methods(domain) do
    goal_methods = [
      %{
        name: "execute_graph",
        type: "multigoal",
        arity: 1,
        predicate: nil,
        decomposition: "execute behavior graph (goal-based)"
      }
    ]

    Map.update(domain, :goal_methods, goal_methods, &(&1 ++ goal_methods))
  end
end
