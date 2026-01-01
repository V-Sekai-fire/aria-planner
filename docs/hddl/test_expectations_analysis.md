# HDDL Parser Test Expectations Analysis

## Question: Is the test correct?

**Answer: YES, the test is correct.** The test expects the normalized AST format that the importer and other parts of the system use.

## Test Expectations

### Domain Definition Test
```elixir
test "parses simple domain definition" do
  hddl = "(define (domain test) (:requirements :strips))"
  
  assert {:ok, {:domain, :test, elements}, _, _, _, _} = Parser.parse(hddl)
  assert {:requirements, _} = List.first(elements)
end
```

**Expected output:** `{:domain, :test, [{:requirements, [:strips]}]}`

### Action Test
```elixir
test "parses action with parameters" do
  ...
  assert {:action, :move, action_elements} = Enum.find(elements, ...)
  assert {:parameters, _} = Enum.find(action_elements, ...)
end
```

**Expected output:** `{:action, :move, [{:parameters, ...}, ...]}`

## Parser Output vs Expected Format

### Current `:action` Parser Structure
```elixir
defparsecp(
  :action,
  string(":action")           # Produces ":action" (string/charlist)
  |> concat(parsec(:identifier))  # Concatenates name → [":action", :name]
  |> concat(repeat(...))          # Concatenates elements → [":action", :name, elem1, elem2, ...]
  |> tag(:action)                 # Wraps as {:action, [":action", :name, elem1, elem2, ...]}
)
```

**Current output:** `{:action, [":action", :move, {:parameters, ...}, ...]}`

**Expected output:** `{:action, :move, [{:parameters, ...}, ...]}`

### The Problem

The `:action` parser includes the `":action"` string in the accumulator before tagging. This means:
- The accumulator becomes `[":action", :name, element1, element2, ...]`
- After `tag(:action)`, it becomes `{:action, [":action", :name, element1, element2, ...]}`
- But the test and importer expect `{:action, :name, [element1, element2, ...]}`

## Why the Test is Correct

1. **Importer expects 3-tuple format:**
   ```elixir
   def import_action({:action, name, elements}) do
     # Expects {:action, name, elements} - 3-tuple
   end
   ```

2. **Normalize module handles 3-tuple format:**
   ```elixir
   defp normalize_element({tag, name, elements}) when is_atom(tag) do
     # Handles {tag, name, elements} - 3-tuple
   end
   ```

3. **Consistent pattern across all element types:**
   - `{:action, name, elements}`
   - `{:method, name, elements}`
   - `{:command, name, elements}`
   - `{:domain, name, elements}`
   - `{:problem, name, elements}`

## The Real Issue

The `:action` parser (and likely other parsers) need to:
1. **Extract the name** from the accumulator
2. **Separate it from elements**
3. **Produce a 3-tuple** `{tag, name, elements}` instead of `{tag, [":action", name, elements...]}`

## Solution

The parsers should use a `map` transformation after `tag` to restructure the output:

```elixir
defparsecp(
  :action,
  string(":action")
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(parsec(:identifier))
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(
    repeat(
      repeat(choice([whitespace, comment])) |> ignore()
      |> choice([...])
    )
  )
  |> tag(:action)
  |> map({AriaPlanner.HDDL.Parser.Helpers, :extract_name_and_elements_from_tagged, []})
)
```

Where `extract_name_and_elements_from_tagged` would:
- Take `{:action, [":action", name, element1, element2, ...]}`
- Return `{:action, name, [element1, element2, ...]}`

## Conclusion

**The test is correct.** The parser needs to be fixed to match the expected format. The issue is that the `:action` parser (and similar parsers) include the keyword string (`":action"`) in the accumulator, which then needs to be stripped out to produce the expected 3-tuple format.

## Next Steps

1. Create a helper function to extract name and elements from tagged parser output
2. Apply this transformation to `:action`, `:method`, `:command`, etc. parsers
3. Ensure `:define_domain` and `:define_problem` also produce the correct 3-tuple format

