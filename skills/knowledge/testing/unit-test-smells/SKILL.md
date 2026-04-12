---
name: unit-test-smells
description: >-
  Detects common unit testing smells and anti-patterns in test code and in plans
  that predict bad tests. Covers implementation coupling, brittle and flaky
  tests, interdependence, logic in tests, over-DRY setup, copy-paste tests,
  framework/library testing, mystery guests, silent failures, god tests, and
  commented-out tests. Use when reviewing tests, test plans, PRs touching tests,
  or validating an implementation plan's testing strategy. Triggers: test smell,
  test review, flaky test, brittle assertion, test quality, anti-pattern,
  it.each, jest, vitest, xUnit, NUnit, MSTest.
---

# Unit test smells and anti-patterns

Apply when **reviewing test code**, **reviewing changes that add or alter tests**, or **reviewing a plan** (test strategy, fixtures, tooling choices) that may **cause** these patterns.

## Operating modes

| Mode | Typical input | `location` field |
|------|---------------|------------------|
| **Review implementation** | Test files, diffs, CI logs mentioning order/flakiness | `file:line`, test name, or `describe`/`it` title |
| **Review plan** | Test strategy sections, fixture design, mocking approach, “how we’ll test” bullets | Plan section / bullet; link to affected module or story |

In **review plan** mode, explicitly flag **design decisions** that make the smells below **likely** (see [Plan-mode risk signals](#plan-mode-risk-signals)).

---

## 1. Implementation coupling

**Signals**

- Tests fail when **internal** structure changes but **observable behavior** does not (private helpers renamed/split, internal call order).
- **Direct** tests of private/static internals (reflection, `internals`, `#private` hacks, `friend` tests) instead of public API or behavior.
- Assertions on **private fields**, hidden caches, or “how it was computed” rather than outputs/contracts.

**Why it hurts** Refactoring becomes expensive; tests document implementation, not requirements.

**Prefer** Public surface, ports/adapters, or golden behavior examples; use seams (injected clocks, IDs, IO) instead of spying on internals.

**Plan-mode risk signals** “We’ll test via internal class X”; no stable API for the behavior; domain logic buried in static singletons.

---

## 2. Brittle tests

**Signals**

- Exact **string** match on messages, stack traces, `JSON.stringify` ordering, or localized text.
- Strict **array/object key order** when the contract is **unordered** (unless order is specified).
- Assertions on **auto-generated** IDs, UUIDs, hashes, or pointer addresses.
- **Timestamps**, “now”, time zones, locale formats, random seeds, **machine paths**, env-specific values in expected output.
- Over-mocked **toasts/snackbar** message text instead of “invoked with structured intent.”

**Prefer** Matchers for subsets/partial strings; sort before compare when order is undefined; freeze time (`FakeTimeProvider` / Jest fake timers); inject ID generator; assert on structured fields.

**Plan-mode risk signals** No clock/ID injection story; assertions tied to log message wording; golden files without normalization pipeline.

---

## 3. Flaky tests

**Signals**

- **Shared mutable** state: module-level vars, singletons, process env, global `Date`/`Math.random` mutation not restored.
- **Async** races: missing `await`, unflushed microtasks, `setTimeout` without control, polling loops with arbitrary sleeps.
- **Order-dependent** results when parallel runners reorder files or tests.
- **Real time** elapsing in tests (retry/backoff) without virtual time.

**Prefer** Isolated fixtures; `beforeEach` reset; avoid shared mutable defaults; deterministic async (`waitFor` with explicit conditions, fake timers); parallel-safe files.

**Plan-mode risk signals** “Integration tests hit real broker/Redis”; global test setup that mutates env; reliance on wall-clock for scheduling logic without abstraction.

---

## 4. Test interdependence

**Signals**

- Passes in IDE / single file run, **fails in full suite** (or reverse).
- Tests assume **DB rows** or files left by **previous** tests.
- **Implicit** “create once in `before`” shared across examples that **mutate** it.
- **Numbering** or “first test creates, second updates” stories in unit suite.

**Prefer** Each test arranges its own data or uses transactions + rollback; unique keys per test; avoid “suite pollution” helpers unless read-only.

**Plan-mode risk signals** Single shared “seed” narrative across stories; no per-test data strategy; “cleanup in last test.”

---

## 5. Logic in tests

**Signals**

- **`if` / `else` / `switch`** in test bodies (branching expectations).
- **Loops** that generate scenarios without `test.each` / parameterized tests (or loops that hide one failing index).
- **`try` / `catch`** used to implement flow control; catching errors **without failing** the test.

**Prefer** One behavior per test; table-driven / parameterized tests; helpers return values—**do not** branch core assertions.

**Plan-mode risk signals** “Smart” test builders with conditional defaults; dynamic expected values computed by re-implementing production logic.

---

## 6. Excessive DRY in tests

**Signals**

- Abstractions (`setupMegaFixture`, deep inheritance) where **reading one test** no longer shows **inputs → action → outcome**.
- **Magical** defaults in factories that obscure the **critical** property for this example.
- “One liner” tests that only call helpers—**intent** is hidden.

**Prefer** Duplication is acceptable when it aids reading; local `arrange` blocks; explicit literals for the few fields that matter; extract only stable, boring mechanics.

**Plan-mode risk signals** Mandate “all tests use MegaFactory”; heavy base test classes for unit tests.

---

## 7. Copy-paste tests

**Signals**

- Near-identical tests differing by **one literal**; repeated arrange/act blocks.

**Prefer** `test.each` / `[Theory]` + `[InlineData]` / `it.each` with **named** columns; shared setup only for **non-behavioral** boilerplate.

**Plan-mode risk signals** “We’ll add five separate tests for each enum value” without parameterization convention.

---

## 8. Testing framework or library internals

**Signals**

- Tests that **verify the mock framework** (`jest.fn` call counts without behavioral consequence).
- Tests for **third-party** behavior (lodash, ORM, router) — unless wrapping with a team-owned contract.
- Tests proving **language features** (that `async/await` works).

**Prefer** Test **your** policy/wiring; thin adapter tests at boundaries; assume stable dependencies unless pinned bug workarounds.

**Plan-mode risk signals** Tasks dedicated to “verify Jest config” via fake tests; no clear ownership boundary around wrappers.

---

## 9. Mystery guest

**Signals**

- Outcome depends on **external file**, **DB seed**, **env var**, or **order of global hooks** not visible in the test.
- Readers must open **other repos** or **migrations** to know why values should match.

**Prefer** Inline minimal data; builders with obvious defaults; colocate seeds; document magic constants **beside** assertion; `given/when/then` structure.

**Plan-mode risk signals** “Tests assume staging data”; reliance on shared spreadsheet fixtures without version control; undocumented env matrix.

---

## 10. Silent failures

**Signals**

- **`catch {}`** / `catch` that only logs; swallowed rejection.
- **Missing `await`** on promise assertions; floating promises in async tests.
- **`toBeDefined()`** (or non-null) on values **always** defined by types/fixture—adds noise, hides real checks.
- **Over-broad** matchers (`toBeTruthy`) masking wrong types.

**Prefer** `expect.assertions(n)` or async matchers; `rejects`/`throws` with specific expectations; assert **specific values** and error types.

**Plan-mode risk signals** “Smoke tests only log errors”; no assertion budget on async flows; linter rules for floating promises disabled “for tests.”

---

## 11. God test

**Signals**

- One test checks **many** unrelated outcomes; long `and` chains; multiple unrelated side effects.
- Failure messages **don’t pinpoint** which expectation broke.
- Mixes **levels** (unit + DB + HTTP) without structure.

**Prefer** Split by behavior; use soft assertion grouping **only** when framework supports rich partial reporting; layered tests (unit vs contract vs e2e).

**Plan-mode risk signals** Single “verify everything” acceptance test with no smaller units; no guidance on test boundaries.

---

## 12. Commented-out tests

**Signals**

- Large **commented** `it`/`test` blocks; “temporarily” disabled tests **without ticket**.

**Prefer** Delete dead code or restore; if skipped, use **explicit** `skip`/`ignore` with **issue link** and reason; time-bound policy.

**Plan-mode risk signals** “We’ll fix tests later” backlog items with no owner; CI allows commented tests to linger.

---

## Severity guide

| Level | Use when |
|-------|----------|
| **error** | Likely **false confidence** (silent catch, missing await), **production blind spots** (no real assertion), or **order-dependent** state that will flake in CI |
| **warning** | **Maintainability** pain: implementation coupling, brittle strings, god tests, mystery guests |
| **note** | **Style / clarity**: mild DRY issues, weak matchers, copy-paste that is still readable |

---

## Finding format (required)

For every issue:

```text
- severity: error | warning | note
- smell: <one of: implementation_coupling | brittle | flaky | interdependence | logic_in_tests | excessive_dry | copy_paste | framework_internals | mystery_guest | silent_failure | god_test | commented_out>
- location: <file:line / test title / plan section>
- issue: <what you observed>
- suggestion: <concrete fix: pattern, refactor, or plan change>
```

Order findings: **error** → **warning** → **note**. If clean, state what was scanned and that no smells were found.

---

## Plan-mode risk signals (summary table)

| If the plan implies… | Smells it tends to create |
|---------------------|---------------------------|
| Static singletons / global registry for domain logic | Flaky, interdependence, implementation coupling |
| No time/ID/IO seams | Brittle, flaky |
| Real network/DB for “unit” tests | Flaky, mystery guest, slow coupling |
| Single end-to-end path as only test | God test, mystery guest |
| Mandatory mega-fixtures / deep test inheritance | Excessive DRY, mystery guest |
| Copy-paste examples per case | copy_paste (prefer parameterization) |
| Assertions on log strings / full error text | Brittle |
| Shared mutable “world” object across tests | Interdependence, flaky |
| “Helper reimplements business rules for expected” | Logic in tests |
| Skipped tests without tracking | commented_out |

---

## Review procedure

1. **Scope**: Identify unit vs integration tests under review; note framework (Jest/Vitest/xUnit/NUnit/MSTest/pytest) for matcher idioms.
2. **Scan for coupling**: private access, internal imports, assertions on non-public state.
3. **Scan for determinism**: shared state, async patterns, time/random, ordering assumptions.
4. **Scan for clarity**: branching in tests, mystery data, DRY hiding intent, duplicated cases.
5. **Scan for trust**: empty catches, missing awaits, weak matchers, giant tests, commented bodies.
6. **Plan mode**: map planned architecture/test strategy to the summary table; call out risks **before** implementation.

---

## Quick remediation cheatsheet

| Smell | One-line direction |
|-------|-------------------|
| Coupling | Test outcomes via public or adapter surfaces |
| Brittle | Match structure; inject time/IDs; avoid exact prose |
| Flaky | Isolate state; deterministic async; fake timers/clocks |
| Interdependence | Per-test data; transactions; no shared mutation |
| Logic in tests | Parameterize or split; no catch-driven control flow |
| Excessive DRY | Local clarity beats clever abstraction |
| Copy-paste | `test.each` / theories |
| Framework tests | Delete or replace with behavior-focused tests |
| Mystery guest | Inline or colocate data; document constants |
| Silent failure | Await; assert errors; avoid empty catch |
| God test | Slice by behavior; layer test types |
| Commented-out | Remove or skip with issue link |
