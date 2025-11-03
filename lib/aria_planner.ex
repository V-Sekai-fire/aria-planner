# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner do
  @moduledoc """
  The external API for the `AriaPlanner` application.

  This module serves as the public interface for the planning and scheduling
  functionalities provided by `AriaPlanner`. All functions intended for use by
  other applications in the umbrella project should be defined or delegated here.

  AriaPlanner depends on AriaMath for mathematical operations.
  """

  # PlanManager delegations
  defdelegate create_plan(persona_id, name, domain_type, opts), to: AriaPlanner.PlanManager
  defdelegate orchestrate_forge_tool(tool_name, args), to: AriaPlanner.PlanManager

  # Client delegations
  defdelegate civil_datetime_to_absolute_microseconds(datetime), to: AriaPlanner.Client
  defdelegate iso8601_to_absolute_microseconds(iso8601_string), to: AriaPlanner.Client
  defdelegate iso8601_duration_to_microseconds(iso8601_duration_string), to: AriaPlanner.Client

  # Solver delegations
  defdelegate run_lazy(domain, initial_state, tasks, opts \\ [], execution \\ false), to: AriaPlanner.Solvers.TensorWorkflowPlanner
end
