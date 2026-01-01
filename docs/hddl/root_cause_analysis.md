# Root Cause Analysis: define_domain Parser Failure

## Simulation of Current Behavior

### Input
```
"(define (domain test) (:requirements :strips))"
```

### Parser Flow

```elixir
defparsec(
  :define_domain,
  repeat(choice([whitespace, comment])) |> ignore()  # Accumulator: []
  |> ignore(string("("))                               # Accumulator: []
  |> ignore(string("define"))                          # Accumulator: []
  |> repeat(choice([whitespace, comment])) |> ignore() # Accumulator: []
  |> ignore(string("("))                               # Accumulator: []
  |> ignore(string("domain"))                          # Accumulator: []
  |> repeat(choice([whitespace, comment])) |> ignore() # Accumulator: []
  |> concat(parsec(:identifier))                       # PROBLEM: concat needs existing list
  |> ignore(string(")"))
  |> concat(repeat(parsec(:domain_element)))
  |> map({Helpers, :build_domain_tuple_from_name_and_elements, []})
)
```

### What Actually Happens

1. **After all `ignore()` calls:** Accumulator is `[]` (empty)
2. **`concat(parsec(:identifier))`:** 
   - `parsec(:identifier)` produces `:test` (atom)
   - `concat` tries to concatenate `[]` with `:test`
   - **Problem:** `concat` concatenates lists, but `:test` is an atom
   - **Result:** The atom is lost or not properly accumulated
3. **`concat(repeat(parsec(:domain_element)))`:**
   - `repeat(...)` produces `[{:requirements, [:strips]}]` (list)
   - `concat` concatenates with accumulator
   - **Result:** Accumulator becomes `[{:requirements, [:strips]}]` (name is missing!)
4. **`map({Helpers, :build_domain_tuple_from_name_and_elements, []})`:**
   - Receives: `[{:requirements, [:strips]}]`
   - Tries to match `[name | elements]` where `name` is atom
   - Fails because first element is `{:requirements, [:strips]}` (tuple, not atom)
   - Falls back to `{:domain, :unknown, []}`

### Root Cause

**`concat` requires an existing list in the accumulator to concatenate with.** After multiple `ignore()` calls, the accumulator is empty `[]`. When `concat(parsec(:identifier))` runs:
- The identifier produces an atom `:test`
- `concat` tries to concatenate `[]` with `:test`
- **Atoms cannot be concatenated with lists using `concat`**
- The atom is lost

### Why `:action` Parser Works

```elixir
defparsecp(
  :action,
  string(":action")                    # Produces ":action" (string = list of chars)
  |> concat(parsec(:identifier))       # concat works because ":action" is already a list
  |> concat(repeat(...))
  |> tag(:action)
)
```

**Key difference:** `string(":action")` produces a string (which is a list of characters), so when `concat(parsec(:identifier))` runs, there's already a list in the accumulator to concatenate with.

### The Fix

We need to ensure there's a list in the accumulator before using `concat`. Two options:

**Option 1: Use `string("domain")` instead of `ignore(string("domain"))`**
- Produces `"domain"` (list) in accumulator
- Then `concat(parsec(:identifier))` works
- Then `concat(repeat(...))` works
- Use `map` to extract name and elements, dropping the `"domain"` string

**Option 2: Wrap identifier in list before concat**
- Use `parsec(:identifier) |> map(fn name -> [name] end)` to wrap in list
- Then `concat` works because there's a list to concatenate with

**Option 3: Don't use `concat` - let sequential accumulation work naturally**
- `parsec(:identifier)` produces atom
- Sequential parsers accumulate: `[atom, element1, element2, ...]`
- But this doesn't work because `ignore()` might reset accumulation

## Recommended Solution

**Use Option 1** - match the `:action` pattern exactly:

```elixir
defparsec(
  :define_domain,
  repeat(choice([whitespace, comment])) |> ignore()
  |> ignore(string("("))
  |> ignore(string("define"))
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> ignore(string("("))
  |> string("domain")                    # Don't ignore - produces "domain" (list)
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(parsec(:identifier))         # Now concat works - "domain" is in accumulator
  |> ignore(string(")"))
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(
    repeat(
      repeat(choice([whitespace, comment])) |> ignore()
      |> parsec(:domain_element)
    )
  )
  |> ignore(string(")"))
  |> map({Helpers, :extract_name_and_elements_from_domain_tagged, []})
)
```

Where `extract_name_and_elements_from_domain_tagged` takes:
- Input: `["domain", :test, {:requirements, [:strips]}, ...]`
- Output: `{:domain, :test, [{:requirements, [:strips]}, ...]}`

This matches the `:action` pattern exactly and should work.

