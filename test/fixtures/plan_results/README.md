# Plan result fixtures

Inputs and expected outcomes for plan-related tests across all domains.

- **plan_create.json** – `AriaCore.Plan.create/1` scenarios: UUIDv7 create, temporal constraints, domain types (blocks_world, navigation, social, economic, exploration, stealth, pert_planner, workflow_test_domain), update, risk assessment, performance metrics, solution graph, execution status transitions.
- **plan_create_validation.json** – Validation error cases: required fields, domain_type inclusion, execution_status inclusion, success_probability range, UUIDv7 format.
- **plan_manager_create_plan.json** – `PlanManager.create_plan/4` scenarios: required params, objectives, todo (backward compat), success probability, all options, and list of domain types for multi-domain test.

Tests use `AriaPlanner.FixtureHelpers.load_fixture/2` with subdir `"plan_results"`.
