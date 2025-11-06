# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.TinyCvrpTest do
  @moduledoc """
  Test-only domain for Tiny CVRP (Capacitated Vehicle Routing Problem).

  Vehicle routing problem where:
  - Multiple vehicles start at a depot
  - Each vehicle has a capacity
  - Each customer has a demand
  - Each customer must be visited exactly once
  - Goal: Minimize total distance/ETA
  """

  use ExUnit.Case, async: true

  alias AriaPlanner.Domains.TinyCvrp
  alias AriaPlanner.Domains.TinyCvrp.Commands.{ReturnToDepot, VisitCustomer}
  alias AriaPlanner.Domains.TinyCvrp.Tasks.RouteVehicles
  alias AriaPlanner.Domains.TinyCvrp.Predicates.{
    VehicleAt,
    CustomerVisited,
    VehicleCapacity
  }

  describe "domain creation" do
    test "creates planning domain with correct structure" do
      {:ok, domain} = TinyCvrp.create_domain()

      assert domain.type == "tiny_cvrp"
      assert "vehicle_at" in domain.predicates
      assert "customer_visited" in domain.predicates
      assert "vehicle_capacity" in domain.predicates
      assert length(domain.actions) >= 2
    end

    test "domain has required actions" do
      {:ok, domain} = TinyCvrp.create_domain()
      action_names = Enum.map(domain.actions, & &1.name)

      assert "a_visit_customer" in action_names
      assert "a_return_to_depot" in action_names
    end
  end

  describe "state initialization" do
    test "initializes state from problem parameters" do
      params = %{
        num_vehicles: 2,
        num_customers: 3,
        vehicle_capacities: [100, 50],
        predicted_demands: [0, 20, 30, 10]
      }

      {:ok, state} = TinyCvrp.initialize_state(params)

      assert state.num_vehicles == 2
      assert state.num_customers == 3
      assert state.total_places == 4
      assert VehicleAt.get(state, 1) == 1
      assert VehicleAt.get(state, 2) == 1
      assert CustomerVisited.get(state, 2) == false
      assert VehicleCapacity.get(state, 1) == 100
      assert VehicleCapacity.get(state, 2) == 50
    end

    test "parses MiniZinc data file" do
      data_file =
        Path.join([
          __DIR__,
          "../../../thirdparty/mznc2024_probs/tiny-cvrp/easy_instance_04.dzn"
        ])

      {:ok, params} = TinyCvrp.parse_dzn_file(data_file)

      assert params.num_vehicles == 4
      assert params.num_customers == 8
      assert is_list(params.vehicle_capacities)
    end
  end

  describe "commands" do
    setup do
      params = %{
        num_vehicles: 2,
        num_customers: 3,
        vehicle_capacities: [100, 50],
        predicted_demands: [0, 20, 30, 10]
      }

      {:ok, state} = TinyCvrp.initialize_state(params)
      %{initial_state: state}
    end

    test "c_visit_customer visits customer", %{initial_state: state} do
      {:ok, new_state} = VisitCustomer.c_visit_customer(state, 1, 2)

      assert VehicleAt.get(new_state, 1) == 2
      assert CustomerVisited.get(new_state, 2) == true
      assert VehicleCapacity.get(new_state, 1) == 80
    end

    test "c_visit_customer enforces capacity constraint", %{initial_state: state} do
      # Try to visit customer with demand 30 using vehicle with capacity 50
      result = VisitCustomer.c_visit_customer(state, 2, 3)

      # Should succeed since 50 >= 30
      assert {:ok, new_state} = result
      assert VehicleCapacity.get(new_state, 2) == 20
    end

    test "c_visit_customer prevents revisiting", %{initial_state: state} do
      {:ok, state} = VisitCustomer.c_visit_customer(state, 1, 2)

      result = VisitCustomer.c_visit_customer(state, 1, 2)

      assert {:error, _} = result
    end

    test "c_return_to_depot returns vehicle to depot", %{initial_state: state} do
      {:ok, state} = VisitCustomer.c_visit_customer(state, 1, 2)
      {:ok, new_state} = ReturnToDepot.c_return_to_depot(state, 1)

      assert VehicleAt.get(new_state, 1) == 1
      assert VehicleCapacity.get(new_state, 1) == 100
    end
  end

  describe "tasks" do
    test "t_route_vehicles generates subtasks" do
      params = %{
        num_vehicles: 2,
        num_customers: 2,
        vehicle_capacities: [100, 100],
        predicted_demands: [0, 20, 30]
      }

      {:ok, state} = TinyCvrp.initialize_state(params)

      subtasks = RouteVehicles.t_route_vehicles(state)
      assert is_list(subtasks)
      assert length(subtasks) > 0
    end
  end

  describe "problem solving" do
    test "solves small instance" do
      params = %{
        num_vehicles: 1,
        num_customers: 2,
        vehicle_capacities: [100],
        predicted_demands: [0, 20, 30]
      }

      {:ok, state} = TinyCvrp.initialize_state(params)

      # Visit first customer
      {:ok, state} = VisitCustomer.c_visit_customer(state, 1, 2)
      assert CustomerVisited.get(state, 2) == true

      # Visit second customer
      {:ok, state} = VisitCustomer.c_visit_customer(state, 1, 3)
      assert CustomerVisited.get(state, 3) == true

      assert TinyCvrp.all_customers_visited?(state)
    end
  end
end
