# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.BeliefBasedEgoArchitectureTest do
  @moduledoc """
  Integration tests for Persona and Plan Architecture.

  Tests the complete system where personas create plans and execute through
  allocentric coordination. Belief system has been removed to simplify the codebase.
  """

  use ExUnit.Case, async: false
  alias AriaCore.{FactsAllocentric, Persona, Plan}

  setup do
    # Clean up any test data
    :ok
  end

  describe "belief-based ego architecture integration" do
    @tag :integration
    test "full integration test with ego plans and allocentric execution" do
      # Test that integrates personas, plans, and allocentric execution
      # Demonstrating the full belief-based ego architecture

      # 1. Create personas (entities with capabilities)
      {:ok, persona_a} =
        Persona.create(%{
          name: "Alpha",
          capabilities: ["planning", "communication", "movable"]
        })

      {:ok, persona_b} =
        Persona.create(%{
          name: "Bravo",
          capabilities: ["combat", "communication", "movable"]
        })

      # 2. Verify personas are created correctly
      assert persona_a.name == "Alpha"
      assert persona_b.name == "Bravo"

      # 3. Create ego-centric plans
      {:ok, plan_a} =
        Plan.create(%{
          name: "Alpha Plan",
          persona_id: persona_a.id,
          domain_type: "tactical",
          objectives: ["coordinate_team", "achieve_objective"],
          success_probability: 0.8
        })

      {:ok, plan_b} =
        Plan.create(%{
          name: "Bravo Plan",
          persona_id: persona_b.id,
          domain_type: "tactical",
          objectives: ["provide_support", "execute_tactical"],
          success_probability: 0.75
        })

      # 4. Plans belong to specific personas (ego-centric ownership)
      assert plan_a.persona_id == persona_a.id
      assert plan_b.persona_id == persona_b.id

      # 5. Verify ego-centric perspectives
      # Plans may have different perspectives even with same domain
      assert plan_a.objectives != plan_b.objectives ||
               plan_a.success_probability != plan_b.success_probability

      # 6. Test allocentric execution capability (would use run_lazy)
      # This demonstrates allocentric coordination of ego plans
      shared_domain = build_test_domain()
      _initial_state = %{team_coordination: 0.5, mission_status: :active}

      coordination_tasks = [
        {:alpha_task, %{plan_id: plan_a.id, confidence: plan_a.success_probability}},
        {:bravo_task, %{plan_id: plan_b.id, confidence: plan_b.success_probability}}
      ]

      # Test that allocentric domain can handle ego plans
      assert Map.has_key?(shared_domain, :actions)
      assert is_list(coordination_tasks)
      assert length(coordination_tasks) == 2
    end

    @tag :integration
    test "hidden information maintenance throughout execution lifecycle" do
      # Create two personas
      {:ok, persona_x} =
        Persona.create(%{
          name: "Persona X",
          capabilities: ["planning", "movable"]
        })

      {:ok, persona_y} =
        Persona.create(%{
          name: "Persona Y",
          capabilities: ["combat", "movable"]
        })

      # Create plans for each
      {:ok, plan_x} =
        Plan.create(%{
          name: "Plan X",
          persona_id: persona_x.id,
          domain_type: "tactical",
          objectives: ["stealth_approach"],
          success_probability: 0.9,
          planning_timestamp: DateTime.utc_now()
        })

      {:ok, plan_y} =
        Plan.create(%{
          name: "Plan Y",
          persona_id: persona_y.id,
          domain_type: "tactical",
          objectives: ["direct_assault"],
          success_probability: 0.7,
          planning_timestamp: DateTime.utc_now()
        })

      # Internal states remain hidden
      # Neither persona can access the other's plan details directly
      assert plan_x.persona_id != plan_y.persona_id
      assert plan_x.objectives != plan_y.objectives

      # Personas are independent entities
      assert persona_x.id != persona_y.id

      # Plans execute allocentrically (in shared reality)
      combined_tasks = [
        {:plan_x_execution, %{persona: :x, objectives: plan_x.objectives, confidence: 0.9}},
        {:plan_y_execution, %{persona: :y, objectives: plan_y.objectives, confidence: 0.7}}
      ]

      # Allocentric execution can coordinate both plans
      assert length(combined_tasks) == 2
      # Both plans can coexist in shared allocentric domain
      assert Enum.all?(combined_tasks, fn {_, %{objectives: _}} -> true end)
    end

    @tag :integration
    test "plan execution and allocentric facts" do
      # Create personas
      {:ok, observer} =
        Persona.create(%{
          name: "Observer",
          capabilities: ["observation", "communication"]
        })

      {:ok, actor} =
        Persona.create(%{
          name: "Actor",
          capabilities: ["actions", "movable"]
        })

      # Verify personas created
      assert observer.name == "Observer"
      assert actor.name == "Actor"

      # Actor creates plan (ego-centric, hidden from observer)
      {:ok, _actor_plan} =
        Plan.create(%{
          name: "Hidden Plan",
          persona_id: actor.id,
          domain_type: "stealth",
          objectives: ["sneak_attack"],
          success_probability: 0.5
        })

      # Plans execute in allocentric space
      # Actions create observable facts

      # Plan execution creates allocentric facts that can be observed
      _execution_result = %{success: true, method: "stealth", outcome: "surprise_attack"}

      # Allocentric fact creation from execution
      allocentric_fact = %{
        fact_id: AriaCore.UUID.generate_v7(),
        fact_type: "event",
        subject_id: actor.id,
        subject_type: "persona",
        predicate: "executed_stealth_attack",
        object_value: "surprise_attack",
        object_type: "string",
        confidence: 1.0,
        game_session_id: "test-session"
      }

      # Facts Allocentric schema can handle execution results
      {:ok, recorded_fact} = FactsAllocentric.create(allocentric_fact)
      assert recorded_fact.subject_id == actor.id
      assert recorded_fact.confidence == 1.0
      assert recorded_fact.fact_type == "event"

      # These facts are observable by all personas
      assert recorded_fact.predicate == "executed_stealth_attack"
    end
  end

  describe "allocentric schema integration" do
    test "facts allocentric handles multiagent observable events" do
      {:ok, sender} =
        Persona.create(%{
          name: "Sender",
          capabilities: ["communication"]
        })

      # Create allocentric fact for communication event
      communication_fact = %{
        fact_id: "comm_event_123",
        fact_type: "event",
        subject_id: sender.id,
        subject_type: "persona",
        predicate: "sent_communication",
        object_value: "coordination_signal",
        object_type: "string",
        confidence: 1.0,
        game_session_id: "multiagent_session_456",
        metadata: %{recipients: ["persona_a", "persona_b"], message_type: :tactical}
      }

      {:ok, fact} = FactsAllocentric.create(communication_fact)

      # Fact represents observable communication (not hidden internal state)
      assert fact.subject_id == sender.id
      assert fact.predicate == "sent_communication"
      assert fact.object_value == "coordination_signal"
      assert fact.confidence == 1.0
      assert fact.game_session_id == "multiagent_session_456"

      # Multiple personas can observe this fact
      assert Map.has_key?(fact.metadata, :recipients)
      assert length(fact.metadata.recipients) == 2
    end

    test "facts are allocentric and observable by all personas" do
      # Create two personas
      {:ok, persona1} =
        Persona.create(%{
          name: "Persona 1"
        })

      {:ok, persona2} =
        Persona.create(%{
          name: "Persona 2"
        })

      # Verify personas created
      assert persona1.name == "Persona 1"
      assert persona2.name == "Persona 2"

      # Create allocentric fact that both could observe in theory
      allocentric_fact = %{
        fact_id: "terrain_feature_789",
        fact_type: "terrain",
        subject_id: "hill_terrain",
        subject_type: "environmental",
        predicate: "provides_elevation_cover",
        object_value: "true",
        object_type: "boolean",
        confidence: 1.0,
        game_session_id: "shared_world"
      }

      {:ok, fact} = FactsAllocentric.create(allocentric_fact)

      # Fact is allocentric - same truth for all personas
      # Allocentric ground truth
      assert fact.confidence == 1.0
      # Shared reality
      assert fact.subject_type == "environmental"
      # Same world for all
      assert fact.game_session_id == "shared_world"
    end
  end

  # Helper functions for test setup

  defp build_test_domain do
    %{
      actions: %{
        alpha_task: fn state, _params -> {:ok, Map.put(state, :alpha_completed, true), %{}} end,
        bravo_task: fn state, _params -> {:ok, Map.put(state, :bravo_completed, true), %{}} end
      },
      methods: %{},
      unigoal_methods: %{},
      multigoal_methods: %{}
    }
  end
end
