# Validation performance — optimization backlog

Notes on possible optimizations for the validation hot path (not the build
path), gathered while profiling a single `JSV.validate/2` call with a flat
schema. These are candidates to pick up independently; nothing here is
implemented yet.

Profiling setup: `bench/eflambe_simple.exs` (eflambe trace → folded flame graph).
Read flame-graph weights as relative shape, not literal nanoseconds (tracing
inflates timings).

---

## 1. Replace the generic `Enum.reduce` dispatch with tail recursion

**Status:** not started · **Priority:** high (hottest path, touches every subschema)

There are two reduce layers on every validation, both per-subschema.

### (a) Per-subschema module dispatch — `lib/jsv/validator.ex:105`

```elixir
reduce(validators, data, vctx, fn {module, mod_validators}, data, vctx ->
  module.validate(data, mod_validators, vctx)
end)
```

`validators` is always a list (`lib/jsv/builder.ex:385` builds it with
`:lists.reverse/1`). This can bypass `reduce/4` entirely with a dedicated
tail-recursive walker that threads `data`/`vctx` as separate accumulators (no
`{data, vctx}` tuple per item) and drops the closure:

```elixir
defp run_mods([{mod, mv} | rest], data, vctx) do
  case mod.validate(data, mv, vctx) do
    {:ok, data, vctx} -> run_mods(rest, data, vctx)
    {:error, vctx}    -> run_mods_err(rest, data, vctx)  # keep collecting errors
  end
end
defp run_mods([], data, vctx), do: return(data, vctx)
```

### (b) The generic `reduce/4` — `lib/jsv/validator.ex:195`

Used by every vocabulary keyword loop (`&validate_keyword/3`) and a few
applicators. Replace the `Enum.reduce` + `{datain, vctx}` accumulator with tail
recursion over a list, keeping the "collect all errors, never stop" semantics:

```elixir
def reduce(list, data, vctx, fun) when is_list(list), do: do_reduce(list, data, vctx, fun)

defp do_reduce([item | rest], data, vctx, fun) do
  case fun.(item, data, vctx) do
    {:ok, data, vctx} -> do_reduce(rest, data, vctx, fun)
    {:error, %ValidationContext{errors: [_ | _]} = vctx} -> do_reduce(rest, data, vctx, fun)
  end
end
defp do_reduce([], data, vctx, fun), do: return(data, vctx)
```

Stays fully generic: still takes `fun`, accumulator is still arbitrary (e.g.
`lib/jsv/vocabulary/v202012/applicator.ex:450` uses a running count, not data).

**Snag — one non-list caller:** every caller passes a list except
`validate_dependent_required/3` (`lib/jsv/vocabulary/v202012/validation.ex:421`),
which reduces over the raw `dependentRequired` **map**. Two options:

- Store it as a list at build time (`take_keyword :dependentRequired`,
  `lib/jsv/vocabulary/v202012/validation.ex:108-109`), so `reduce/4` can be
  list-only. (Preferred.)
- Or add a `when is_map(...)` clause that does `:maps.to_list/1` first.

Caller inventory (all lists unless noted):
`validator.ex:106` (validators list), `core.ex:139`, `unevaluated.ex:36/50/66`,
`applicator.ex:284/342/450/474/499`, `v7/applicator.ex:60`, `validation.ex:153`,
`validation.ex:421` (**map** — the only one).

---

## 2. Gate the cast stack on a build-time "has casts" flag

**Status:** not started · **Priority:** medium · **Note:** related TODO already
at `lib/jsv/validator.ex:88`

`validate(%Subschema{})` (`lib/jsv/validator.ex:93-114`) runs `push_cast` +
`pop_apply_cast` for **every subschema**, even when no cast exists anywhere — a
`Map.put` + `Map.delete` + tuple allocation per node, pure waste for plain JSON
schemas (no `defschema` / `x-jsv-cast`).

**Why per-node skipping is unsafe:** the nil entries track nesting depth so the
cast is applied by the *topmost* validator at a `data_path` (so sibling keywords
validate on un-cast data). Skipping a parent's nil push would let a child apply
its cast too early — a behavior change.

**What's safe:** gate the *entire* mechanism on
`cast_active = opts.cast and root_has_casts?`. If no casts exist in the whole
tree, nothing is ever applied, so skipping push/pop is a guaranteed no-op:

```elixir
vctx =
  if vctx.cast_active do
    %{vctx | schema_path: sub.schema_path, cast_stacks: push_cast(cast_stacks, data_path, cast)}
  else
    %{vctx | schema_path: sub.schema_path}
  end
```

Requires:
- A `has_casts?` boolean computed at build (the builder already isolates the
  `cast` field at `lib/jsv/builder.ex:378-382`, so it can aggregate a root flag).
- A new field on `JSV.Root` (`lib/jsv/root.ex:11` has no feature flags today).
- Surface it into the context once in `JSV.Validator.context/3` as
  `cast_active`.

---

## 3. Gate `evaluated` tracking on a build-time "uses unevaluated*" flag

**Status:** not started · **Priority:** medium (biggest payoff on real nested
data, which the flat bench under-weights)

`validate_in/5` and `validate_as/4` (`lib/jsv/validator.ex:259-307`) push
`evaluated: [%{} | evaluated]` and run `merge_tracked`/`add_evaluated` on **every
property and array item**, solely to support `unevaluatedProperties` /
`unevaluatedItems`. Most schemas don't use those keywords.

Same safe pattern as §2: a build-time flag "this root uses `unevaluated*`". When
false, skip the per-key `[%{} | evaluated]` bookkeeping and the merge. Keeps the
full code path for schemas that need it.

---

## Minor notes

- `JSV.Validator.context/3` builds a 9-field struct per top-level call — inherent
  per-call cost, nothing obvious to remove.
- `String.length/2` is called twice on strings with both `minLength` and
  `maxLength` (codepoint counting). Considered a micro-optimization for now; keep
  the clear, spec-correct code.
