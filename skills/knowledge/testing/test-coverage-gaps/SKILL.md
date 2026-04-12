---
name: test-coverage-gaps
description: >-
  Identifies missing tests and coverage gaps: happy paths per public API, error
  paths, boundaries, concurrency/unicode/large-input edges, branch and
  short-circuit coverage, multi-parameter combinations, state machines, return
  type unions, regression tests before fixes, and pragmatic coverage vs
  mutation targets. Use in review plan mode to list test categories the plan
  must address; in review changes mode to map code paths to tests and flag
  untested branches. Triggers: missing tests, coverage gaps, branch coverage,
  edge cases, test plan review, untested code paths, mutation testing, review
  plan, review changes.
---

# Test coverage gaps (review)

Apply when evaluating **whether tests match the real behavior surface** of a unit—public API, errors, boundaries, branches, state, and return shapes—from a **plan** (before implementation) or **changed code** (diffs and existing tests).

## Operating modes

| Mode | Typical input | What you produce |
|------|---------------|------------------|
| **Review plan** | Feature plan, test plan section, acceptance criteria, task breakdown | Checklist of **test categories** the plan must explicitly call out (with rationale), plus risks if omitted |
| **Review changes** | Implementation diff, touched files, adjacent tests | **Path-to-test map**: for each meaningful branch/path, cite `file:line` (or symbol) and whether a test names/asserts it; flag **untested** paths with severity |

**Review plan**: do not pretend to know branches that do not exist yet—derive categories from the **described behavior**, API surface, and stated non-functional concerns (concurrency, time, scale).

**Review changes**: prefer **evidence**: quote branch predicates, `switch` arms, `catch` types, early returns, and the test(s) that exercise them. If coverage tools or mutation reports exist in the repo/CI, reference them; if not, reason from the code.

If both plan and code exist, **reconcile**: flag plan items with no test task, and code branches with no test reference.

## Category checklist (use in both modes)

Use this as the **master rubric**. In **review plan**, turn each relevant row into an explicit plan bullet or task. In **review changes**, mark each row **covered / partial / gap** with file references.

### Happy path coverage

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| Every **public** function/method/exported type surface has at least one test for the **primary success** scenario | List each public entry point and its success criteria | For each export, name the test (or flag **gap**) |

Include constructors/factories that enforce invariants if they are part of the public contract.

### Error paths

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| **Exceptions**, **thrown errors**, **rejected promises**, **error callbacks**, **Result/Either** failure channels | State which error types/messages/codes are contractually relevant | Map each `throw`, `reject`, `catch`, err callback branch to a test that asserts behavior (not only “does not throw”) |
| **Invalid returns** where failure is encoded as a value (`null`, sentinel, boolean false) | Plan negative assertions | Flag branches that return error values without a test |

### Boundary values

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| **Off-by-one** around loops, slices, ranges, pagination (`start`, `count`, inclusive/exclusive ends) | Call out index/range semantics | Flag boundary lines (first/last/empty segment) |
| **Empty**: `[]`, `""`, `0`, `null`, `undefined`, empty maps/sets, optional absent vs present | Plan one test per meaningful emptiness | Match predicates like `length === 0`, `!x`, optional chaining |
| **Singleton** collections / single character strings | When behavior differs from empty or many | Flag branches that treat `1` specially |
| **Min/max** of domains (timeouts, IDs, numeric limits) | Plan domain limits from requirements | Flag comparisons to constants or `Number.MAX_*` |
| **Integer overflow / wrap** boundaries for numeric code | If language/platform allows wrap or BigInt paths | Flag arithmetic on wide integers |

### Edge cases

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| **Concurrent** access (races, locks, async interleaving, promise ordering) | State concurrency model | Flag shared mutable state without synchronization tests |
| **Unicode** / combining characters / RTL / emoji / **special characters** in strings and paths | If user input or parsing is involved | Flag normalization-sensitive code without cases |
| **Very large** inputs (memory, time limits, streaming vs buffering) | If scalability is claimed | Flag unbounded loops/allocations |
| **Negative numbers**, **non-integer** where integers expected, **float precision** | For numeric code | Flag branches on `<0`, epsilon compares, rounding |
| **Timezone-sensitive** dates (DST, UTC vs local, “same instant” vs “same calendar day”) | If dates cross zones or serialize | Flag `Date`/`Instant` usage without TZ-fixed or explicit cases |

### Branch coverage

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| Every **`if` / `else`**, **`switch`** arm including **`default`**, **ternaries** | Plan “one positive per arm” where arms differ in behavior | List each arm; cite test or **gap** |
| **Short-circuit**: `&&`, `\|\|`, `??`—both “right-hand never evaluated” and “evaluated” | Mention when side effects or performance differ | Flag compound conditions with only one truth-table row tested |

Treat **guard clauses** and **early returns** as branches.

### Input combinations (multi-parameter)

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| Pairs/tuples of parameters that **interact** (not only varying one dimension) | Use a combination table or pairwise plan | Flag `if (a && b)`-style logic tested only in isolation |
| Illegal combinations that should **reject** or **normalize** | Explicit negative combo cases | Map validation to tests |

Prefer **small Cartesian subsets** that hit distinct interaction logic; document why each combo matters.

### State transitions

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| **Valid** transitions between states (explicit state machine or implicit flags) | Enumerate states and allowed edges | Each edge has a test; name setup/invoke/assert |
| **Invalid** transitions must **fail** or **no-op** per spec | Plan forbidden transitions | Flag missing rejection tests |

### Return value coverage

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| All **observable return shapes** (e.g. `string \| null \| undefined`, empty vs populated collections, discriminated unions) | List return variants from API doc or types | For each return path, assert the variant used by callers |

### Regression awareness

| Expectation | Review plan | Review changes |
|-------------|-------------|----------------|
| Bug fixes include a **failing test first** (or in the same change set) that reproduces the bug | Plan “regression test” task tied to bug ID | If fix has no new/updated test, **warning** unless impossibly non-deterministic—then document alternative guard |

### Coverage metrics guidance

| Metric | What it measures | Meaningful targets | Theatrical / misleading |
|--------|------------------|--------------------|-------------------------|
| **Line coverage** | Executed lines | Good **floor** for greenfield; watch for “one happy path” hitting many lines | High % with **no asserts** or only integration smoke |
| **Branch coverage** | Taken branches (`if`, `?:`, `\|\|`, `&&`, `??`, `switch`) | Better signal than line for logic-heavy code; prioritize when cyclomatic complexity is high | 100% branch on **trivial** getters; ignores **value** correctness |
| **Mutation testing** | Tests kill small seeded faults | Strong **feedback** on weak assertions; use to find “coverage theater” | Chasing 100% mutants on UI/IO without stable harness; slow flakiness if nondeterministic |

**Guidance**: treat metrics as **diagnostics**, not goals. Prefer **risk-based** depth: complex, security-sensitive, or frequently changed code gets branch + mutation attention; thin CRUD may stop at strong happy/error paths and boundaries.

## Output templates

### Review plan — summary

```markdown
## Test coverage — plan gaps

### Must add to plan
- [Category]: [why it applies to this feature] → [concrete test tasks or acceptance criteria]

### Risks if omitted
- ...

### Metrics- Suggested minimum: [line vs branch vs mutation] because [risk profile]
```

### Review changes — summary

```markdown
## Test coverage — code vs tests

### Untested or weakly tested (severity: error | warning | note)
- `path:line` — [branch/path description] — [missing test or weak assertion]

### Covered (sample)
- `path:line` — exercised by `[test file::name]` — [what is asserted]

### Combinations / state / returns
- [table or bullet map]

### Metrics (if available)
- [tool] — [numbers] — [interpretation: real signal vs theater]
```

## Severity hints

| Severity | When |
|----------|------|
| **error** | Public contract, security, money, data loss, or bug-prone branch with no test |
| **warning** | Error path, boundary, or combination likely wrong without coverage |
| **note** | Nice-to-have edge, already partially covered, or low-risk helper |

## Execution notes

- **Scope**: match the **unit under review** (single module, service, or PR). Do not demand exhaustive E2E for every branch unless the plan says so.
- **Tests must assert**: executing code under coverage tools without expectations is a **gap**.
- **Language mapping**: “promise rejection” ↔ `Future` failure ↔ `Result::Err` ↔ Go `(err != nil)`—use the ecosystem’s idioms.
- When uncertain whether a path is dead, say so and suggest **static analysis** or a **spike** instead of inventing branches.
