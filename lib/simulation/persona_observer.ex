# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# DEPRECATED: This module is no longer used. Belief system functionality
# has been removed to simplify the codebase. Belief-related features were
# not used in the core planning execution loop.
defmodule AriaPlanner.PersonaObserver do
  @moduledoc """
  DEPRECATED: Persona observation system for Belief-Based Ego Architecture.

  This module is deprecated and no longer used. Belief system functionality
  has been removed to simplify the codebase as it was not used in core
  planning execution.

  All functions are stubs that return the persona unchanged.
  """

  alias AriaCore.Persona

  @doc """
  DEPRECATED: Process observation to update persona beliefs.
  Returns persona unchanged.
  """
  @spec process_observation(Persona.t(), map()) :: {:ok, Persona.t()}
  def process_observation(persona, _observation) do
    {:ok, persona}
  end

  @doc """
  DEPRECATED: Process communication to form beliefs about sender.
  Returns persona unchanged.
  """
  @spec process_communication(Persona.t(), map()) :: {:ok, Persona.t()}
  def process_communication(persona, _communication) do
    {:ok, persona}
  end

  @doc """
  DEPRECATED: Update beliefs based on execution outcomes.
  Returns persona unchanged.
  """
  @spec update_beliefs_from_outcomes(Persona.t(), [map()]) :: {:ok, Persona.t()}
  def update_beliefs_from_outcomes(persona, _outcomes) do
    {:ok, persona}
  end
end
