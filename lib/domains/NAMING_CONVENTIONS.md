# Domain Naming Conventions

This document defines the naming conventions for all domains in `apps/aria_planner/lib/domains/`.

## Overview

All domains follow consistent naming patterns for modules, files, functions, and identifiers.

## Directory Structure

```
domains/
  {domain_name}/          # snake_case directory name
    domain.ex             # Main domain module
    commands/             # Command modules
      {command_name}.ex   # snake_case file name
    tasks/                # Task modules
      {task_name}.ex      # snake_case file name
    multigoals/           # Multigoal modules
      {multigoal_name}.ex # snake_case file name
    predicates/           # Predicate modules
      {predicate_name}.ex # snake_case file name
    {helper_modules}.ex   # Optional helper modules (snake_case)
```

## Module Names

**Pattern**: `AriaPlanner.Domains.{DomainName}.{Category}.{ModuleName}`

- **Domain Name**: PascalCase (e.g., `FoxGeeseCorn`, `Neighbours`, `TinyCvrp`, `AircraftDisassembly`)
- **Category**: PascalCase (`Commands`, `Tasks`, `Multigoals`, `Predicates`)
- **Module Name**: PascalCase (e.g., `CrossEast`, `TransportAll`, `MaximizeGrid`, `ScheduleActivities`)

**Examples:**

- `AriaPlanner.Domains.FoxGeeseCorn.Commands.CrossEast`
- `AriaPlanner.Domains.Neighbours.Tasks.MaximizeGrid`
- `AriaPlanner.Domains.TinyCvrp.Multigoals.RouteVehicles`
- `AriaPlanner.Domains.AircraftDisassembly.Predicates.ResourceAssigned`

## File Names

**Pattern**: snake_case matching the module name

**Examples:**

- Module: `CrossEast` → File: `cross_east.ex`
- Module: `TransportAll` → File: `transport_all.ex`
- Module: `MaximizeGrid` → File: `maximize_grid.ex`
- Module: `ScheduleActivities` → File: `schedule_activities.ex`
- Module: `ResourceAssigned` → File: `resource_assigned.ex`

## Domain Type Strings

**Pattern**: snake_case (used in domain.ex `type` field)

**Examples:**

- `"fox_geese_corn"`
- `"neighbours"`
- `"tiny_cvrp"`
- `"aircraft_disassembly"`

## Action Names

**Pattern**: `"a_{action_name}"` (snake_case, used in domain.ex actions list)

**Examples:**

- `"a_cross_east"`
- `"a_assign_value"`
- `"a_visit_customer"`
- `"a_start_activity"`

## Command Functions

**Pattern**: `c_{command_name}` (snake_case)

**Examples:**

- `c_cross_east/4`
- `c_assign_value/4`
- `c_visit_customer/3`
- `c_start_activity/4`

## Task Functions

**Pattern**: `t_{task_name}` (snake_case)

**Examples:**

- `t_transport_all/1`
- `t_maximize_grid/1`
- `t_route_vehicles/1`
- `t_schedule_activities/1`

## Multigoal Functions

**Pattern**: `m_{multigoal_name}` (snake_case)

**Examples:**

- `m_transport_all/1`
- `m_maximize_grid/1`
- `m_route_vehicles/1`
- `m_schedule_activities/1`

## Task/Multigoal Names in domain.ex

**Pattern**: snake_case (no prefix, used in `register_task_methods` and `register_goal_methods`)

**Examples:**

- `"transport_all"`
- `"maximize_grid"`
- `"route_vehicles"`
- `"schedule_activities"`

## Predicate Functions

**Pattern**: Standard function names `get` and `set` (arity varies by predicate)

**Examples:**

- `EastFox.get/1`, `EastFox.set/2`
- `GridValue.get/3`, `GridValue.set/4`
- `VehicleAt.get/2`, `VehicleAt.set/3`
- `ResourceAssigned.get/3`, `ResourceAssigned.set/4`

## Predicate Names

**Pattern**: snake_case (used in domain.ex predicates list)

**Examples:**

- `"east_fox"`, `"west_geese"`, `"boat_location"`
- `"grid_value"`
- `"vehicle_at"`, `"customer_visited"`, `"vehicle_capacity"`
- `"activity_status"`, `"precedence"`, `"resource_assigned"`

## Helper Modules

**Pattern**: PascalCase module names, snake_case file names

**Examples:**

- `AriaPlanner.Domains.AircraftDisassembly.StateHelpers` → `state_helpers.ex`
- `AriaPlanner.Domains.AircraftDisassembly.StateInitialization` → `state_initialization.ex`
- `AriaPlanner.Domains.AircraftDisassembly.DznParser` → `dzn_parser.ex`

## Summary

| Element                          | Convention                | Example             |
| -------------------------------- | ------------------------- | ------------------- |
| Directory name                   | snake_case                | `fox_geese_corn/`   |
| File name                        | snake_case                | `cross_east.ex`     |
| Module name                      | PascalCase                | `CrossEast`         |
| Domain type string               | snake_case                | `"fox_geese_corn"`  |
| Action name                      | `"a_{name}"` (snake_case) | `"a_cross_east"`    |
| Command function                 | `c_{name}` (snake_case)   | `c_cross_east/4`    |
| Task function                    | `t_{name}` (snake_case)   | `t_transport_all/1` |
| Multigoal function               | `m_{name}` (snake_case)   | `m_transport_all/1` |
| Task/multigoal name in domain.ex | snake_case (no prefix)    | `"transport_all"`   |
| Predicate name                   | snake_case                | `"east_fox"`        |
| Predicate functions              | `get`, `set`              | `get/1`, `set/2`    |

## Verification

All domains follow these conventions:

- ✅ `fox_geese_corn` (FoxGeeseCorn)
- ✅ `neighbours` (Neighbours)
- ✅ `tiny_cvrp` (TinyCvrp)
- ✅ `aircraft_disassembly` (AircraftDisassembly)
