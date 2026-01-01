# aria_planner

AI planner for complex decision-making using HTN (Hierarchical Task Network) planning.

## Features

- HTN planning with lazy refinement
- Temporal constraints with ISO 8601 format
- Entity requirements and capabilities
- Multi-goal planning
- Command execution with side effects
- HDDL 2.1 + aria_planner extensions import/export

## HDDL Import/Export

aria_planner supports importing and exporting planning domains and problems in HDDL (Hierarchical Domain Definition Language) format, including aria_planner-specific extensions.

### Importing HDDL

Import HDDL domain or problem files into aria_planner structs:

```elixir
# Import from file
{:ok, domain} = AriaPlanner.HDDL.import_from_file("domains/fox_geese_corn.hddl")

# Import from string
hddl_string = """
(define (domain test)
  (:requirements :strips :typing :temporal :hierarchical)
  (:aria-domain-metadata
    :name "Test Domain"
    :domain-type navigation
    :version 1
  )
)
"""

{:ok, domain} = AriaPlanner.HDDL.import_from_string(hddl_string)
```

### Exporting to HDDL

Export aria_planner domains and plans to HDDL format:

```elixir
# Export domain to string
hddl_string = AriaPlanner.HDDL.export_to_string(domain)

# Export domain to file
:ok = AriaPlanner.HDDL.export_to_file(domain, "output.hddl")

# Export plan to HDDL
{:ok, plan} = AriaCore.Plan.get(plan_id)
hddl_string = AriaPlanner.HDDL.export_to_string(plan)
```

### Validating HDDL

Validate HDDL syntax without importing:

```elixir
case AriaPlanner.HDDL.validate_hddl(hddl_string) do
  :ok -> IO.puts("Valid HDDL")
  {:error, reason} -> IO.puts("Invalid: #{reason}")
end
```

### HDDL Extensions

aria_planner extends HDDL 2.1 with the following features:

- **`:aria-temporal-metadata`**: ISO 8601 duration and datetime support
- **`:aria-domain-metadata`**: Domain metadata (ID, name, description, type, version, state)
- **`:aria-command-metadata`**: Command-specific metadata (failure handling, retries)
- **`:aria-predicate-schemas`**: Predicate schema definitions
- **`:aria-initial-state`**: Initial planner state
- **`:aria-plan`**: Plan structure and metadata
- **`:command`**: Commands (special actions with side effects)
- **`:multigoal`**: Multi-goal definitions
- **`:goal-method`**: Goal decomposition methods
- **`:multigoal-method`**: Multi-goal decomposition methods
- **`:entities`**: Entity definitions with capabilities

See `docs/proposals/HDDL_ARIA_EXTENSION.md` for complete specification.

### Example HDDL Domain

```hddl
(define (domain fox_geese_corn)
  (:requirements :strips :typing :temporal :hierarchical)

  (:aria-domain-metadata
    :name "Fox Geese Corn Domain"
    :domain-type navigation
    :version 1
    :state active
  )

  (:entities
    (:entity agent
      :type agent
      :capabilities (:navigation :transport)
    )
  )

  (:durative-action a_cross_east
    :parameters (?fox_count ?geese_count ?corn_count)
    :duration (= ?duration 300)
    :condition (and
      (at start (boat_location west))
      (over all (>= west_fox ?fox_count))
    )
    :effect (and
      (at start (decrease west_fox ?fox_count))
      (at end (increase east_fox ?fox_count))
    )
    :aria-temporal-metadata (
      :duration "PT5M"
      :requires-entities (
        (:entity agent :capabilities (:navigation :transport))
      )
    )
  )
)
```

## Installation

Add `aria_planner` to your dependencies:

```elixir
def deps do
  [
    {:aria_planner, git: "https://github.com/V-Sekai-fire/aria-planner.git"}
  ]
end
```

## Usage

See the main documentation for detailed usage examples and API reference.

## License

MIT

