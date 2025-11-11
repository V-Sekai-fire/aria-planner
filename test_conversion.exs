alias AriaPlanner.Planner.MiniZincConverter
alias AriaPlanner.Domains.FoxGeeseCorn

# Test converting the domain
{:ok, domain} = FoxGeeseCorn.create_domain()

# Get the first action to test conversion
action = List.first(domain.actions)
IO.puts("Testing action: #{inspect(action.name)}")
IO.puts("Preconditions: #{inspect(action.preconditions)}")

# Convert the action directly
case MiniZincConverter.convert_command(action) do
  {:ok, minizinc} ->
    IO.puts("\nGenerated MiniZinc for action:")
    IO.puts(minizinc)
    IO.puts("\n" <> String.duplicate("=", 50))
  
  error ->
    IO.puts("Error: #{inspect(error)}")
end

# Test converting the full domain
{:ok, minizinc} = MiniZincConverter.convert_domain(domain)

# Check if constraints are present
IO.puts("\nFull domain MiniZinc (first 1000 chars):")
IO.puts(String.slice(minizinc, 0, 1000))

