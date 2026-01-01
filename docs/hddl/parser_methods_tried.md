# HDDL Parser Methods Tried and Blacklisted

This document tracks parsing methods attempted for `define_domain` and `define_problem` patterns, why they failed, and what we learned.

## Problem Statement

Parse HDDL top-level constructs:

- `(define (domain name) ...elements...)` → `{:domain, name, elements}`
- `(define (problem name) ...elements...)` → `{:problem, name, elements}`

The challenge: correctly accumulating both the `name` (atom) and `elements` (list) into a single accumulator that can be transformed into the expected tuple.

## Blacklisted Methods

### ❌ Method 1: Direct Sequential Accumulation

**Attempt:**

```elixir
defparsec(
  :define_domain,
  ...
  |> parsec(:identifier)  # Produces atom
  |> ignore(string(")"))
  |> repeat(parsec(:domain_element))  # Produces list
  |> map({Helpers, :build_domain_tuple_from_name_and_elements, []})
)
```

**Result:** Only elements accumulated, name was lost.

**Why it failed:** After `ignore()`, the name atom wasn't in the accumulator when `repeat()` started accumulating elements. Sequential parsers don't automatically preserve previous results when `ignore()` is used.

**Status:** BLACKLISTED - Sequential accumulation without explicit concatenation loses intermediate results.

---

### ❌ Method 2: Tag + Post-Traverse Combination

**Attempt:**

```elixir
defparsecp(
  :define_name_and_elements,
  tag(parsec(:identifier), :name)
  |> ignore(string(")"))
  |> tag(repeat(parsec(:domain_element)), :elements)
  |> post_traverse({__MODULE__, :combine_tags_to_keyword_list})
)
```

**Result:** Compilation error - `post_traverse` doesn't accept module function tuples the same way `map` does.

**Why it failed:** `post_traverse` requires a different function signature and calling convention than `map`. The callback function needs to handle `(rest, acc, context, line, offset, byte_offset)` parameters.

**Status:** BLACKLISTED - Post-traverse requires different function signature and is more complex than needed.

---

### ❌ Method 3: Concat with Wrapped Name

**Attempt:**

```elixir
defparsec(
  :define_domain,
  ...
  |> concat(parsec(:identifier) |> map({List, :wrap, []}))  # Wrap name in list
  |> ignore(string(")"))
  |> concat(repeat(parsec(:domain_element)))
  |> map({Helpers, :build_domain_tuple_from_name_and_elements, []})
)
```

**Result:** Name still not accumulated correctly.

**Why it failed:** `concat` concatenates lists, but wrapping the identifier in a list and then using `concat` didn't preserve the structure we needed. The accumulator structure was still incorrect.

**Status:** BLACKLISTED - Wrapping + concat doesn't solve the accumulation problem.

---

### ❌ Method 4: Tag Name + Tag Elements (Separate Tags)

**Attempt:**

```elixir
defparsec(
  :define_domain,
  ...
  |> tag(parsec(:identifier), :name)
  |> ignore(string(")"))
  |> tag(repeat(parsec(:domain_element)), :elements)
  |> map({Helpers, :build_domain_tuple_from_tagged, []})
)
```

**Result:** Helper received `{:elements, [element1, ...]}` - the `:name` tag was lost.

**Why it failed:** `tag` replaces the accumulator with a tagged tuple. When you tag twice sequentially, the second tag replaces the first, so only the last tag remains in the accumulator.

**Status:** BLACKLISTED - Sequential `tag` calls replace each other, only the last tag remains.

---

### ❌ Method 5: Concat After Ignore (Current Issue)

**Attempt:**

```elixir
defparsec(
  :define_domain,
  ...
  |> ignore(string("domain"))
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(parsec(:identifier))  # Concat after ignore
  |> ignore(string(")"))
  |> concat(repeat(parsec(:domain_element)))
  |> map({Helpers, :build_domain_tuple_from_name_and_elements, []})
)
```

**Result:** Only elements accumulated: `{:requirements, [:strips]}` - name atom is lost.

**Why it's failing:** `concat` concatenates lists, but when used after `ignore()`, there's nothing in the accumulator to concatenate with. The identifier produces an atom, not a list, so `concat` doesn't work as expected.

**Status:** CURRENT ISSUE - `concat` after `ignore()` doesn't accumulate the atom correctly.

---

## Working Pattern (Reference)

### ✅ Method Pattern (Works Correctly)

**Pattern from `:method` parser:**

```elixir
defparsecp(
  :method,
  string(":method")  # Produces string (list of chars)
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(parsec(:identifier))  # Concat works because string is already in accumulator
  |> repeat(choice([whitespace, comment])) |> ignore()
  |> concat(
    repeat(parsec(:domain_element))
  )
  |> tag(:method)
)
```

**Why it works:** The `string(":method")` produces a charlist (which is a list), so when `concat(parsec(:identifier))` runs, it concatenates the identifier atom into the existing list. Then `concat(repeat(...))` adds the elements.

**Key insight:** `concat` needs something already in the accumulator (a list) to concatenate with.

---

## Lessons Learned

1. **`ignore()` resets accumulation context:** After `ignore()`, previous results aren't automatically preserved unless explicitly concatenated.

2. **`concat` requires existing list:** `concat` concatenates lists, so it needs something already in the accumulator to work with. An atom alone won't work.

3. **Sequential `tag` calls replace each other:** Only the last `tag` result remains in the accumulator.

4. **`post_traverse` has different signature:** Requires `(rest, acc, context, line, offset, byte_offset)` parameters, not just the accumulator.

5. **The `:method` pattern works because:** It starts with `string(":method")` which produces a list, then `concat` can add to that list.

---

## Recommended Solution Path

Based on the working `:method` pattern, we should:

1. **Option A:** Start with a dummy string/list before the identifier to give `concat` something to work with:

   ```elixir
   |> ignore(string("domain"))
   |> string("")  # Empty string produces empty list
   |> concat(parsec(:identifier))
   |> concat(repeat(...))
   ```

2. **Option B:** Use `reduce` to build the accumulator explicitly:

   ```elixir
   |> parsec(:identifier)
   |> reduce(fn name, acc -> [name | acc] end)
   |> repeat(...)
   ```

3. **Option C:** Don't use `concat` - let sequential parsers accumulate naturally, but ensure the identifier result is preserved:

   ```elixir
   |> parsec(:identifier)
   |> map(fn name -> [name] end)  # Wrap in list
   |> repeat(...)  # This should accumulate into the list
   ```

4. **Option D:** Match the `:method` pattern exactly by starting with a non-ignored string:
   ```elixir
   |> string("domain")  # Don't ignore, produces list
   |> concat(parsec(:identifier))
   |> concat(repeat(...))
   |> map(fn [_, name | elements] -> {:domain, name, elements} end)  # Drop "domain" string
   ```

---

## Current Status

**Last attempted:** Method 5 (concat after ignore) - still failing, name not accumulated.

**Next to try:** Option C or Option D from recommended solutions above.

**Working reference:** `:method` parser (lines 193-204 in `lib/hddl/parser.ex`)

---

## Code Reuse Achievements

✅ **Successfully extracted:** `:identifier` parser (lines 702-708) - now reused in:

- `:action`
- `:durative_action`
- `:command`
- `:method`
- `:durative_method`
- `:goal_method`
- `:define_domain`
- `:define_problem`

This eliminates ~40 lines of duplicate identifier parsing code.

---

## Notes

- All attempts preserved the `:method` parser pattern as a working reference
- The `:identifier` parser extraction was successful and is now systematically reused
- The core issue is accumulator management when using `ignore()` before `concat()`
