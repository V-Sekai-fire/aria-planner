# Plan: Define Custom Concat Combinator

## Root Cause

The built-in NimbleParsec `concat` combinator requires an existing list in the accumulator to concatenate with. When used after `ignore()` calls that leave an empty accumulator, `concat` cannot concatenate an atom (from `:identifier`) with an empty list, causing the name to be lost.

## Solution

Define a custom `concat_any` combinator that:
1. Handles empty accumulators by wrapping the parser result in a list
2. Handles existing lists by concatenating the parser result
3. Works with both atoms and lists as parser results
4. Can be used as a drop-in replacement for `concat` in our use case

## Implementation

### Step 1: Create custom combinator helper function
**File:** `lib/hddl/parser/helpers.ex`

Add a function that handles concatenation logic:

```elixir
@doc """
Concatenates a parser result into the accumulator, handling empty accumulators and atoms.

If accumulator is empty, wraps the result in a list.
If accumulator is a list, concatenates the result to it.
If result is an atom, wraps it in a list first.
If result is already a list, concatenates it directly.
"""
@spec concat_any_helper(list(), term()) :: list()
def concat_any_helper(acc, result) when is_list(acc) and is_list(result) do
  acc ++ result
end
def concat_any_helper(acc, result) when is_list(acc) do
  # acc is list, result is atom or other - wrap result and concatenate
  acc ++ [result]
end
def concat_any_helper(acc, result) when is_list(result) do
  # acc is empty/atom, result is list - use result as new accumulator
  result
end
def concat_any_helper(_acc, result) do
  # Both are atoms/empty - wrap result in list
  [result]
end
```

### Step 2: Create combinator macro/function
**File:** `lib/hddl/parser.ex`

Add a combinator that uses `post_traverse` to apply the concatenation:

```elixir
# Custom concat combinator that handles empty accumulators and atoms
defp concat_any(combinator) do
  combinator
  |> post_traverse({__MODULE__, :concat_any_post_traverse})
end

# Post-traverse callback for concat_any
defp concat_any_post_traverse(rest, acc, context, line, offset, byte_offset) do
  # acc is [previous_results..., new_result]
  # We need to take the last element (new_result) and concatenate with previous
  case acc do
    [] ->
      {rest, [], context, line, offset, byte_offset}
    [new_result] ->
      # Only new result, wrap in list
      {rest, [new_result], context, line, offset, byte_offset}
    previous_results when is_list(previous_results) ->
      # Take last element as new result, rest as previous accumulator
      {new_result, previous} = List.pop_at(previous_results, -1)
      concatenated = AriaPlanner.HDDL.Parser.Helpers.concat_any_helper(previous, new_result)
      {rest, concatenated, context, line, offset, byte_offset}
    other ->
      # Unexpected structure
      {rest, other, context, line, offset, byte_offset}
  end
end
```

Actually, wait - `post_traverse` receives the full accumulator. Let me reconsider...

### Alternative Approach: Use `reduce` with accumulator transformation

```elixir
# Custom concat combinator using reduce
defp concat_any(combinator) do
  combinator
  |> reduce({AriaPlanner.HDDL.Parser.Helpers, :concat_any_reduce, []})
end
```

And in helpers:
```elixir
@spec concat_any_reduce(list()) :: list()
def concat_any_reduce(acc) do
  # acc is [previous_results..., new_result]
  case acc do
    [] -> []
    [new_result] -> [new_result]
    previous_results when is_list(previous_results) ->
      {new_result, previous} = List.pop_at(previous_results, -1)
      concat_any_helper(previous, new_result)
    other -> other
  end
end
```

### Step 3: Update define_domain to use custom concat
**File:** `lib/hddl/parser.ex` (lines 709, 712)

Replace:
```elixir
|> concat(parsec(:identifier))
...
|> concat(
  repeat(...)
)
```

With:
```elixir
|> concat_any(parsec(:identifier))
...
|> concat_any(
  repeat(...)
)
```

### Step 4: Test the custom combinator
Verify that:
1. Empty accumulator + atom → `[atom]`
2. List accumulator + atom → `list ++ [atom]`
3. Empty accumulator + list → `list`
4. List accumulator + list → `list1 ++ list2`

## Files to Modify

1. `lib/hddl/parser.ex` - Add `concat_any` combinator and update `define_domain`
2. `lib/hddl/parser/helpers.ex` - Add `concat_any_helper` and `concat_any_reduce` functions

## Testing

After implementation, test with:
```bash
mix test test/hddl/parser_test.exs:10
```

Expected: Test passes with `{:domain, :test, [{:requirements, [:strips]}]}`

