# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.PersonaObserver do
  @moduledoc """
  Persona observation system for Belief-Based Ego Architecture.

  Provides mechanisms for personas to observe allocentric reality and form
  ego-centric beliefs. Acts as the bridge between shared world state and
  individual agent perspectives.
  """

  alias AriaCore.Persona

  @doc """
  Process observation to update persona beliefs.

  Observations allow personas to learn about others through the allocentric
  shared reality, maintaining information asymmetry while enabling intelligent
  belief formation.
  """
  @spec process_observation(Persona.t(), map()) :: {:ok, Persona.t()}
  def process_observation(persona, observation) do
    case observation do
      %{entity: entity_id, action: action, confidence: confidence} ->
        # Entity-specific observation
        current_beliefs = Persona.get_beliefs_about(persona, entity_id)

        updated_beliefs =
          Map.put(current_beliefs, "observed_#{action}", %{
            "observed_at" => DateTime.utc_now(),
            "confidence" => confidence,
            "pattern" => extract_pattern(action)
          })

        current_con = Map.get(persona.belief_confidence, entity_id, %{})
        updated_con = Map.put(current_con, action, confidence)

        updated_persona = %{
          persona
          | beliefs_about_others: Map.put(persona.beliefs_about_others, entity_id, updated_beliefs),
            belief_confidence: Map.put(persona.belief_confidence, entity_id, updated_con),
            last_observations: Map.put(persona.last_observations, entity_id, DateTime.utc_now())
        }

        {:ok, updated_persona}

      %{type: :allocentric_fact, fact: fact} ->
        # Allocentric fact observation
        process_allocentric_fact_observation(persona, fact)

      _ ->
        # Unknown observation type
        {:ok, persona}
    end
  end

  @doc """
  Process communication to form beliefs about sender.

  Communications are observable events that personas can use to build
  beliefs about others' intentions and capabilities.
  """
  @spec process_communication(Persona.t(), map()) :: {:ok, Persona.t()}
  def process_communication(persona, communication) do
    sender_id = extract_sender_id(communication)
    content_analysis = analyze_communication_content(communication)

    current_beliefs = Persona.get_beliefs_about(persona, sender_id)

    updated_beliefs =
      Map.merge(current_beliefs, %{
        "communication_pattern" => content_analysis,
        "last_communication" => DateTime.utc_now()
      })

    # Update confidence based on communication consistency
    current_con = Map.get(persona.belief_confidence, sender_id, %{})
    consistency_score = calculate_communication_consistency(persona, sender_id, content_analysis)
    updated_con = Map.put(current_con, "communication_reliability", consistency_score)

    updated_persona = %{
      persona
      | beliefs_about_others: Map.put(persona.beliefs_about_others, sender_id, updated_beliefs),
        belief_confidence: Map.put(persona.belief_confidence, sender_id, updated_con)
    }

    {:ok, updated_persona}
  end

  @doc """
  Update beliefs based on execution outcomes.

  When plans execute in allocentric reality, personas observe the outcomes
  and update their beliefs about planning effectiveness and agent capabilities.
  """
  @spec update_beliefs_from_outcomes(Persona.t(), [map()]) :: {:ok, Persona.t()}
  def update_beliefs_from_outcomes(persona, outcomes) do
    # Process each outcome to update beliefs
    updated_beliefs =
      Enum.reduce(outcomes, persona.beliefs_about_others, fn outcome, acc ->
        case outcome do
          %{result: "success", agent: agent_id, action: action} ->
            agent_beliefs = Map.get(acc, agent_id, %{})
            success_patterns = Map.get(agent_beliefs, "success_patterns", %{})
            updated_patterns = Map.update(success_patterns, action, 1, &(&1 + 1))
            Map.put(acc, agent_id, Map.put(agent_beliefs, "success_patterns", updated_patterns))

          %{result: "failure", agent: agent_id, action: action} ->
            agent_beliefs = Map.get(acc, agent_id, %{})
            failure_patterns = Map.get(agent_beliefs, "failure_patterns", %{})
            updated_patterns = Map.update(failure_patterns, action, 1, &(&1 + 1))
            Map.put(acc, agent_id, Map.put(agent_beliefs, "failure_patterns", updated_patterns))

          _ ->
            acc
        end
      end)

    updated_persona = %{persona | beliefs_about_others: updated_beliefs}
    {:ok, updated_persona}
  end

  # Private helper functions

  @spec extract_pattern(String.t()) :: String.t()
  defp extract_pattern(action) do
    # Extract behavioral patterns from observed actions
    cond do
      String.contains?(action, "movement") -> "mobile"
      String.contains?(action, "attack") -> "aggressive"
      String.contains?(action, "defend") -> "defensive"
      String.contains?(action, "communicate") -> "social"
      String.contains?(action, "plan") -> "strategic"
      true -> "neutral"
    end
  end

  @spec process_allocentric_fact_observation(Persona.t(), AriaCore.FactsAllocentric.t()) :: {:ok, Persona.t()}
  defp process_allocentric_fact_observation(persona, fact) do
    # Process observation of allocentric fact to update ego beliefs
    subject_id = fact.subject_id
    predicate = fact.predicate
    object_value = Jason.decode!(fact.object_value)

    current_beliefs = Persona.get_beliefs_about(persona, subject_id)

    updated_beliefs =
      Map.put(current_beliefs, "allocentric_#{predicate}", %{
        "value" => object_value,
        "observed_at" => DateTime.utc_now(),
        "confidence" => fact.confidence
      })

    updated_persona = %{
      persona
      | beliefs_about_others: Map.put(persona.beliefs_about_others, subject_id, updated_beliefs)
    }

    {:ok, updated_persona}
  end

  @spec extract_sender_id(map()) :: String.t()
  defp extract_sender_id(communication) do
    case communication do
      %{sender: %{id: id}} -> id
      %{sender: id} when is_binary(id) -> id
      %{sender_id: id} -> id
      _ -> "unknown_sender"
    end
  end

  @spec analyze_communication_content(map()) :: map()
  defp analyze_communication_content(communication) do
    content = communication[:content] || communication[:message] || ""
    type = communication[:type] || :unknown

    %{
      "type" => type,
      "content_length" => String.length(inspect(content)),
      "intent_signals" => extract_intent_signals(content),
      "analyzed_at" => DateTime.utc_now()
    }
  end

  @spec extract_intent_signals(String.t()) :: [String.t()]
  defp extract_intent_signals(content) do
    content_str = inspect(content)
    signals = []

    signals =
      if String.contains?(content_str, ["coordinate", "together", "team"]) do
        ["cooperative" | signals]
      else
        signals
      end

    signals =
      if String.contains?(content_str, ["attack", "strike", "assault"]) do
        ["aggressive" | signals]
      else
        signals
      end

    signals =
      if String.contains?(content_str, ["defend", "protect", "guard"]) do
        ["defensive" | signals]
      else
        signals
      end

    signals =
      if String.contains?(content_str, ["retreat", "withdraw", "fallback"]) do
        ["cautious" | signals]
      else
        signals
      end

    signals
  end

  @spec calculate_communication_consistency(Persona.t(), String.t(), map()) :: float()
  defp calculate_communication_consistency(persona, sender_id, content_analysis) do
    # Calculate consistency of sender's communication patterns
    previous_comms =
      Map.get(persona.beliefs_about_others, sender_id, %{})
      |> Map.get("communication_history", [])

    if Enum.empty?(previous_comms) do
      # First communication - baseline confidence
      0.5
    else
      # Compare intent signals with historical patterns
      current_signals = content_analysis["intent_signals"]
      historical_signals = extract_historical_intent_signals(previous_comms)

      # Simple consistency calculation
      intersection =
        MapSet.intersection(
          MapSet.new(current_signals),
          MapSet.new(historical_signals)
        )

      union =
        MapSet.union(
          MapSet.new(current_signals),
          MapSet.new(historical_signals)
        )

      if MapSet.size(union) == 0 do
        0.5
      else
        # Scale 0.2-1.0
        MapSet.size(intersection) / MapSet.size(union) * 0.8 + 0.2
      end
    end
  end

  @spec extract_historical_intent_signals([map()]) :: [String.t()]
  defp extract_historical_intent_signals(history) do
    Enum.flat_map(history, fn comm ->
      Map.get(comm, "intent_signals", [])
    end)
  end
end
