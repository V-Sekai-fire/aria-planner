# Plan: Define Custom Concat Combinator for HDDL Parser

## Root Cause

The built-in NimbleParsec `concat` combinator requires an existing list in the accumulator to concatenate with. When `define_domain` uses `concat(parsec(:identifier))` after multiple `ignore()` calls, the accumulator is empty `[]`, and `concat` cannot concatenate an atom `:test` with an empty list, causing the name to be lost.

**Current broken behavior:**

- After `ignore()` calls: accumulator = `[]`
- `concat(parsec(:identifier))` produces `:test` (atom)
- `concat` tries to concatenate `[]` with `:test` → fails, atom lost
- Only elements accumulate: `[{:requirements, [:strips]}]`

## Solution

Create a custom `concat_any` combinator that:

1. Handles empty accumulators by wrapping the parser result in a list
2. Handles existing lists by concatenating the parser result
3. Works with both atoms and lists as parser results
4. Uses `reduce` to transform the accumulator after parsing

## Implementation Steps

### Step 1: Add helper function for concatenation logic

**File:** `lib/hddl/parser/helpers.ex`

Add function to handle concatenation:

```elixir
@doc """
Concatenates a new result into an accumulator, handling empty accumulators and atoms.

## Behavior:
- Empty accumulator + atom → `[atom]`
- Empty accumulator + list → `list`
- List accumulator + atom → `list ++ [atom]`
- List accumulator + list → `list1 ++ list2`
"""
@spec concat_any_reduce(list()) :: list()
def concat_any_reduce(acc) when is_list(acc) do
  # acc is [previous_results..., new_result]
  case acc do
    [] -> []
    [new_result] ->
      # Only new result, ensure it's a list
      if is_list(new_result), do: new_result, else: [new_result]
    previous_results ->
      # Split: last element is new_result, rest is previous accumulator
      {new_result, previous} = List.pop_at(previous_results, -1)
      concat_any_helper(previous, new_result)
  end
end
def concat_any_reduce(other), do: other

# Helper to concatenate new_result into previous accumulator
@spec concat_any_helper(list(), term()) :: list()
defp concat_any_helper(previous, new_result) when is_list(previous) and is_list(new_result) do
  previous ++ new_result
end
defp concat_any_helper(previous, new_result) when is_list(previous) do
  # previous is list, new_result is atom/other - wrap and concatenate
  previous ++ [new_result]
end
defp concat_any_helper(previous, new_result) when is_list(new_result) do
  # previous is empty/atom, new_result is list - use new_result
  new_result
end
defp concat_any_helper(_previous, new_result) do
  # Both are atoms/empty - wrap new_result in list
  [new_result]
end
```

### Step 2: Create concat_any combinator

**File:** `lib/hddl/parser.ex` (after line 57, before domain elements section)

Add the combinator function:

```elixir
  # Custom concat combinator that handles empty accumulators and atoms
  # Works like concat but handles cases where accumulator is empty or result is an atom
  defp concat_any(combinator) do
    combinator
    |> reduce({AriaPlanner.HDDL.Parser.Helpers, :concat_any_reduce, []})
  end
```

### Step 3: Update define_domain parser

**File:** `lib/hddl/parser.ex` (lines 709, 712)

Replace `concat` with `concat_any`:

```elixir
  defparsec(
    :define_domain,
    repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string("("))
    |> ignore(string("define"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> ignore(string("("))
    |> ignore(string("domain"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat_any(parsec(:identifier))  # Changed from concat
    |> ignore(string(")"))
    |> repeat(choice([whitespace, comment])) |> ignore()
    |> concat_any(  # Changed from concat
      repeat(
        repeat(choice([whitespace, comment])) |> ignore()
        |> parsec(:domain_element)
      )
    )
    |> ignore(string(")"))
    |> map({AriaPlanner.HDDL.Parser.Helpers, :build_domain_tuple_from_name_and_elements, []})
  )
```

### Step 4: Update define_problem parser (if needed)

**File:** `lib/hddl/parser.ex` (lines 722-746)

If `define_problem` has similar issues, apply the same fix.

### Step 5: Remove debug IO.inspect

**File:** `lib/hddl/parser/helpers.ex` (line 64)

Remove the debug `IO.inspect` call from `build_domain_tuple_from_name_and_elements` since we'll have proper accumulation.

### Step 6: Test

Run the test to verify:

```bash
mix test test/hddl/parser_test.exs:10
```

**Expected result:** Test passes with `{:domain, :test, [{:requirements, [:strips]}]}`

**Expected accumulator flow:**

1. After `ignore()` calls: `[]`
2. After `concat_any(parsec(:identifier))`: `[:test]` (atom wrapped in list)
3. After `concat_any(repeat(...))`: `[:test, {:requirements, [:strips]}]`
4. After `map`: `{:domain, :test, [{:requirements, [:strips]}]}`

## Verification Checklist

- [ ] `concat_any` combinator compiles without errors
- [ ] `concat_any_reduce` handles empty accumulator + atom case
- [ ] `concat_any_reduce` handles list accumulator + atom case
- [ ] `concat_any_reduce` handles empty accumulator + list case
- [ ] `concat_any_reduce` handles list accumulator + list case
- [ ] `define_domain` test passes
- [ ] All other parser tests still pass
- [ ] No compilation warnings

## Files to Modify

1. `lib/hddl/parser.ex` - Add `concat_any` combinator, update `define_domain` parser
2. `lib/hddl/parser/helpers.ex` - Add `concat_any_reduce` and `concat_any_helper` functions

## Alternative Consideration

If `reduce` doesn't work as expected with the accumulator structure, we can use `post_traverse` instead:

```elixir
defp concat_any(combinator) do
  combinator
  |> post_traverse({__MODULE__, :concat_any_post_traverse})
end

defp concat_any_post_traverse(rest, acc, context, line, offset, byte_offset) do
  # Transform acc here
  {rest, transformed_acc, context, line, offset, byte_offset}
end
```

But `reduce` should work since it receives the full accumulator list.
