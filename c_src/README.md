# Chuffed Solver Integration

This project uses **standard MiniZinc with Chuffed solver** via command-line interface.

## Requirements

1. **MiniZinc**: MiniZinc constraint modeling language
   - Download from: https://www.minizinc.org/
   - Install MiniZinc and ensure `minizinc` is in your PATH

2. **Chuffed Solver**: Chuffed must be available as a MiniZinc solver
   - Chuffed is typically included with MiniZinc distributions
   - Verify with: `minizinc --solvers` (should list "chuffed")

## Usage

The Chuffed integration is handled automatically by `AriaPlanner.Solvers.ChuffedMiniZinc` and `AriaPlanner.Solvers.AriaChuffedSolver`.

No native compilation is required - the system uses the standard MiniZinc CLI with `--json-stream` for structured output.

## Testing

Run the solver tests:

```bash
mix test test/solvers/
```

Tests will skip gracefully if MiniZinc or Chuffed is not available.
