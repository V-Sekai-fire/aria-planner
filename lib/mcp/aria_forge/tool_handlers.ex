# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule MCP.AriaForge.ToolHandlers do
  @moduledoc """
  MCP Tool Handlers for AriaForge integration.
  
  This module provides handlers for MCP tool calls, serving as a bridge
  between the MCP protocol and the aria_planner functionality.
  """

  alias AriaPlanner.PlanManager
  alias AriaCore.Plan
  alias UUIDv7

  @doc """
  Handles a tool call from the MCP protocol.
  
  Returns {:ok, result, new_state} on success or {:error, message, new_state} on failure.
  """
  @spec handle_tool_call(String.t(), map(), map()) :: {:ok, map(), map()} | {:error, String.t(), map()}
  def handle_tool_call("create_plan", args, state) do
    persona_id = Map.get(args, "persona_id", "default_persona")
    name = Map.get(args, "name", "Unnamed Plan")
    domain_type = Map.get(args, "domain_type", "tiny_cvrp")
    objectives = Map.get(args, "objectives", [])
    success_probability = Map.get(args, "success_probability", 0.5)
    run_lazy = Map.get(args, "run_lazy", false)

    case PlanManager.create_plan(persona_id, name, domain_type,
           success_probability: success_probability,
           todo: if(run_lazy, do: [], else: objectives)
         ) do
      {:ok, plan} ->
        plan_id = plan.id
        resource_uri = "aria://plans/#{plan_id}"

        result = %{
          content: [
            %{
              type: "text",
              text: Jason.encode!(%{
                "id" => plan_id,
                "plan_id" => plan_id,
                "name" => name,
                "domain_type" => domain_type,
                "persona_id" => persona_id,
                "execution_status" => if(run_lazy, do: "pending", else: "planned"),
                "run_lazy" => run_lazy,
                "resource_uri" => resource_uri
              })
            }
          ]
        }

        new_state = %{
          state
          | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1,
            created_resources: Map.put(Map.get(state, :created_resources) || %{}, resource_uri, plan)
        }

        {:ok, result, new_state}

      {:error, reason} ->
        {:error, "Failed to create plan: #{inspect(reason)}", state}
    end
  end

  def handle_tool_call("create_planning_domain", args, state) do
    domain_type = Map.get(args, "domain_type", "default_domain")
    entities = Map.get(args, "entities", [])

    resource_uri = "aria://domain/#{domain_type}"

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{
            "domain_type" => domain_type,
            "entities" => entities,
            "resource_uri" => resource_uri
          })
        }
      ]
    }

    new_state = %{
      state
      | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1,
        created_resources: Map.put(Map.get(state, :created_resources) || %{}, resource_uri, %{
          domain_type: domain_type,
          entities: entities
        })
    }

    {:ok, result, new_state}
  end

  def handle_tool_call("list_domain_tasks", args, state) do
    domain_type = Map.get(args, "domain_type")

    tasks = get_domain_tasks(domain_type)

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{tasks: tasks})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("list_domain_actions", args, state) do
    domain_type = Map.get(args, "domain_type")

    actions = get_domain_actions(domain_type)

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{actions: actions})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("list_domain_entities", args, state) do
    domain_type = Map.get(args, "domain_type")
    include_capabilities = Map.get(args, "include_capabilities", false)

    entities = get_domain_entities(domain_type, include_capabilities)

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{entities: entities})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("list_domain_multigoals", args, state) do
    domain_type = Map.get(args, "domain_type")

    multigoals = get_domain_multigoals(domain_type)

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{multigoals: multigoals})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("list_domain_commands", args, state) do
    domain_type = Map.get(args, "domain_type")

    commands = get_domain_commands(domain_type)

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{commands: commands})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("add_domain_element", args, state) do
    domain_type = Map.get(args, "domain_type", "default_domain")
    element_type = Map.get(args, "element_type", "task")
    name = Map.get(args, "name", "Unnamed Element")
    data = Map.get(args, "data", %{})
    run_lazy = Map.get(args, "run_lazy", false)

    element_id = UUIDv7.generate()
    resource_uri = "aria://domain_elements/#{domain_type}/#{element_type}/#{element_id}"

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{
            "id" => element_id,
            "element_id" => element_id,
            "name" => name,
            "element_type" => element_type,
            "domain_type" => domain_type,
            "resource_uri" => resource_uri,
            "data" => data,
            "run_lazy" => run_lazy,
            "execution_status" => if(run_lazy, do: "pending", else: "planned")
          })
        }
      ]
    }

    new_state = %{
      state
      | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1,
        created_resources: Map.put(Map.get(state, :created_resources) || %{}, resource_uri, %{
          id: element_id,
          name: name,
          element_type: element_type,
          domain_type: domain_type,
          data: data,
          run_lazy: run_lazy
        })
    }

    {:ok, result, new_state}
  end

  def handle_tool_call("list_domain_elements", args, state) do
    domain_type = Map.get(args, "domain_type")
    element_type = Map.get(args, "element_type")

    elements = get_domain_elements(domain_type, element_type)

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{elements: elements})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("get_execution_state", _args, state) do
    execution_state = %{
      current_time: DateTime.utc_now(),
      weather: "clear",
      temperature: 20,
      total_players: 0,
      players: %{}
    }

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(execution_state)
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("update_execution_state", args, state) do
    updates = %{}

    updates =
      if Map.has_key?(args, "weather_type") do
        Map.put(updates, :weather, Map.get(args, "weather_type"))
      else
        updates
      end

    updates =
      if Map.has_key?(args, "advance_time_minutes") do
        minutes = Map.get(args, "advance_time_minutes")
        Map.put(updates, :time_advanced, minutes)
      else
        updates
      end

    updates =
      if Map.has_key?(args, "add_player") do
        player_data = Map.get(args, "add_player")
        Map.put(updates, :player_added, player_data)
      else
        updates
      end

    result = %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(%{updated: updates})
        }
      ]
    }

    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}

    {:ok, result, new_state}
  end

  def handle_tool_call("unknown_tool", _args, state) do
    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}
    {:error, "Tool not found: unknown_tool", new_state}
  end

  def handle_tool_call(tool_name, _args, state) do
    new_state = %{state | prompt_uses: (Map.get(state, :prompt_uses) || 0) + 1}
    {:error, "Tool not found: #{tool_name}", new_state}
  end

  # Helper functions to get domain information
  defp get_domain_tasks(nil), do: []
  defp get_domain_tasks("tiny_cvrp"), do: ["route_vehicles"]
  defp get_domain_tasks("fox_geese_corn"), do: ["transport_all"]
  defp get_domain_tasks("neighbours"), do: ["maximize_grid"]
  defp get_domain_tasks("navigation"), do: ["navigate", "reach_destination"]
  defp get_domain_tasks("tactical"), do: ["secure_perimeter", "establish_communication"]
  defp get_domain_tasks(_), do: []

  defp get_domain_actions(nil), do: []
  defp get_domain_actions("tiny_cvrp"), do: ["a_visit_customer", "a_return_to_depot"]
  defp get_domain_actions("fox_geese_corn"), do: ["a_cross_east", "a_cross_west"]
  defp get_domain_actions("neighbours"), do: ["a_assign_value"]
  defp get_domain_actions("tactical"), do: ["move", "attack", "defend"]
  defp get_domain_actions(_), do: []

  defp get_domain_entities(_domain_type, _include_capabilities), do: []

  defp get_domain_multigoals(nil), do: []
  defp get_domain_multigoals("tiny_cvrp"), do: ["route_vehicles"]
  defp get_domain_multigoals("fox_geese_corn"), do: ["transport_all"]
  defp get_domain_multigoals("neighbours"), do: ["maximize_grid"]
  defp get_domain_multigoals(_), do: []

  defp get_domain_commands(nil), do: []
  defp get_domain_commands("tiny_cvrp"), do: ["c_visit_customer", "c_return_to_depot"]
  defp get_domain_commands("fox_geese_corn"), do: ["c_cross_east", "c_cross_west"]
  defp get_domain_commands("neighbours"), do: ["c_assign_value"]
  defp get_domain_commands(_), do: []

  defp get_domain_elements(_domain_type, _element_type), do: []
end

