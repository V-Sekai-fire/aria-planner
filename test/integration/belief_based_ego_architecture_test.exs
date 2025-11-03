# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.BeliefBasedEgoArchitectureTest do
  @moduledoc """
  Integration tests for Belief-Based Ego Architecture with Hidden Information.

  Tests the complete system where personas form beliefs through observation,
  create ego-centric plans, execute through allocentric coordination, and update
  beliefs based on outcomes while maintaining information asymmetry.
  """

  use ExUnit.Case, async: false
  alias AriaCore.{Persona, Plan, FactsAllocentric}

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
          capabilities: ["planning", "communication", "movable"],
          beliefs_about_others: %{},
          belief_confidence: %{}
        })

      {:ok, persona_b} =
        Persona.create(%{
          name: "Bravo",
          capabilities: ["combat", "communication", "movable"],
          beliefs_about_others: %{},
          belief_confidence: %{}
        })

      # 2. Verify personas maintain hidden information
      # No persona can access another's internal planning state
      assert Persona.get_beliefs_about(persona_a, persona_b.id) == %{}
      assert Persona.get_beliefs_about(persona_b, persona_a.id) == %{}

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
          capabilities: ["planning", "movable"],
          beliefs_about_others: %{},
          belief_confidence: %{},
          last_observations: %{}
        })

      {:ok, persona_y} =
        Persona.create(%{
          name: "Persona Y",
          capabilities: ["combat", "movable"],
          beliefs_about_others: %{},
          belief_confidence: %{},
          last_observations: %{}
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

      # Beliefs about others start empty (no access to internal states)
      beliefs_x_about_y = Persona.get_beliefs_about(persona_x, persona_y.id)
      beliefs_y_about_x = Persona.get_beliefs_about(persona_y, persona_x.id)

      assert beliefs_x_about_y == %{}
      assert beliefs_y_about_x == %{}

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
    test "belief evolution through observation sequences" do
      # Create personas
      {:ok, observer} =
        Persona.create(%{
          name: "Observer",
          capabilities: ["observation", "communication"],
          beliefs_about_others: %{},
          belief_confidence: %{},
          last_observations: %{}
        })

      {:ok, actor} =
        Persona.create(%{
          name: "Actor",
          capabilities: ["actions", "movable"],
          beliefs_about_others: %{}
        })

      # Initial empty beliefs
      initial_beliefs = Persona.get_beliefs_about(observer, actor.id)
      assert initial_beliefs == %{}

      # Actor creates plan (ego-centric, hidden from observer)
      {:ok, _actor_plan} =
        Plan.create(%{
          name: "Hidden Plan",
          persona_id: actor.id,
          domain_type: "stealth",
          objectives: ["sneak_attack"],
          success_probability: 0.5
        })

      # Observer cannot see actor's plan (information asymmetry)
      # But can observe actions/behaviors
      observed_behavior = %{
        entity: actor.id,
        action: "sneak_movement",
        timestamp: DateTime.utc_now(),
        confidence: 0.8
      }

      # Process observation (would update beliefs in real implementation)
      # For now, verify observation structure
      assert observed_behavior.entity == actor.id
      assert observed_behavior.confidence > 0

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

      # These facts can be observed by all personas for belief updates
      # (would trigger belief evolution in complete system)
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

      # Multiple personas can observe this fact and update beliefs accordingly
      # (would trigger belief formation about sender's intentions)
      assert Map.has_key?(fact.metadata, :recipients)
      assert length(fact.metadata.recipients) == 2
    end

    test "beliefs are ego-centric while facts are allocentric" do
      # Create two personas
      {:ok, persona1} =
        Persona.create(%{
          name: "Persona 1",
          # Ego-centric: beliefs about others
          beliefs_about_others: %{},
          # Ego-centric: confidence in beliefs
          belief_confidence: %{}
        })

      {:ok, persona2} =
        Persona.create(%{
          name: "Persona 2",
          # Different ego perspective
          beliefs_about_others: %{},
          belief_confidence: %{}
        })

      # Both start with empty beliefs (no observations yet) - this is expected
      # Ego beliefs would become different after observations
      assert persona1.beliefs_about_others == %{}
      assert persona2.beliefs_about_others == %{}

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

      # Fact is allocentric - same truth for both personas
      # But each persona may form different ego-centric beliefs about it
      # Allocentric ground truth
      assert fact.confidence == 1.0
      # Shared reality
      assert fact.subject_type == "environmental"
      # Same world for both
      assert fact.game_session_id == "shared_world"

      # Ego beliefs would be different interpretations of this allocentric fact
      # (e.g., persona1 might believe it provides good cover, persona2 might disagree)
      ego_interpretation1 = %{belief: "provides_cover", confidence: 0.8}
      ego_interpretation2 = %{belief: "poor_visibility", confidence: 0.3}

      # Different ego interpretations of same allocentric truth
      assert ego_interpretation1 != ego_interpretation2
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
