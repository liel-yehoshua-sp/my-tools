---
name: test-data-management
description: >-
  Reviews test data design: inline vs shared fixtures, factories/builders with
  defaults and overrides, minimal relevant fields, isolation and cleanup,
  realistic shapes vs dummy mocks, faker/randomness and seeding, parameterized
  tests, file fixtures and versioning, sensitive data, and fixed clock/timezones.
  Use in review plan mode to recommend a test data strategy for a feature or
  suite, or in review changes mode to audit diffs and existing tests. Triggers:
  test data review, fixture strategy, factory pattern tests, flaky test data,
  faker, parametrize, test.each, seed random, test isolation, PII in tests.
---

# Test data management (review)

Apply when evaluating **how tests obtain, shape, and isolate data**—from **plans** (new suite or feature test approach) or **implementation** (factories, fixtures, DB setup, mocks).

## Operating modes

| Mode | Typical input | `location` field |
|------|---------------|------------------|
| **Review plan** | Test strategy notes, ADR, “how we’ll test X”, backlog acceptance criteria | Area/feature name, suite boundary, or doc section |
| **Review changes** | Diffs, new/changed tests, factories, `conftest`, seed scripts | `file:line` or test name / describe block |

**Review plan**: recommend defaults (inline-first, factories, isolation mechanism, time strategy, parametrize where tables help). Call out risks (shared DB, randomness, large fixtures) before code exists.

**Review changes**: cite concrete violations and improvements against the rules below.

If both exist, prioritize **changed** tests and data helpers, then **shared** fixtures consumed by those tests.

## Inline vs shared data

| Rule | Severity hints |
|------|----------------|
| Prefer **data visible in the test** (inline literals, small object literals) so intent is obvious | **warning** when a one-liner test jumps to a distant fixture for trivial values |
| **Shared fixtures** are acceptable for **large or complex** blobs that would obscure the test (big JSON, multi-field domain graphs, repeated legal/compliance-shaped payloads) | **note** when extraction improves readability |
| When sharing, the test should still **name or assert the few fields that matter** for this case | **warning** when shared setup hides which properties drive the assertion |

## Factories and builders

| Rule | Severity hints |
|------|----------------|
| Use **factory functions** or **builders** with **sensible defaults** and **overridable fields** (e.g. `createUser({ name: 'Alice' })`, `UserBuilder().WithRole(Admin).Build()`) | **warning** when tests manually construct wide graphs repeatedly |
| Defaults should produce **valid** instances for the majority of tests; overrides should be **sparse** | **error** when defaults are invalid for the common path and every test repeats boilerplate |
| Avoid **god factories** that know every scenario; compose smaller factories | **warning** when one factory encodes many unrelated variants behind flags |

## Minimal data

| Rule | Severity hints |
|------|----------------|
| Include **only fields relevant** to the behavior under test; omit unrelated “real world” completeness | **note** when noise makes the expected behavior unclear |
| Prefer **focused assertions** on those fields over asserting entire large objects | **warning** when brittle snapshots or full-structure equality mask intent |
| Document **why** a non-obvious field is present when it matters | **note** when mysterious fields look accidental |

## Data isolation

| Rule | Severity hints |
|------|----------------|
| Each test should **create its own data** or operate on **explicit inputs**; avoid **shared mutable** statics/singletons unless immutable | **error** when order-dependence or cross-test mutation is likely |
| With a **shared database**: use **transactions + rollback**, **per-test schema**, **truncation**, or **containers** with clear lifecycle; document the chosen pattern | **error** when cleanup is missing and tests touch persistent shared state |
| Parallel runs: ensure **unique keys** (suffixes, UUIDs) where uniqueness matters | **warning** when fixed IDs collide under parallel CI |

## Realistic vs dummy data

| Rule | Severity hints |
|------|----------------|
| Mocks and stubs should reflect **realistic shapes** (required keys, types, nesting); `{}`, `"test"`, or `null` everywhere can **mask** validation and integration bugs | **warning** when stubs are too vacuous for the code under test |
| Avoid **unnecessary detail** that does not serve the scenario | **note** when realism becomes clutter—trim to contract-relevant fields |
| Prefer **representative values** (valid enums, plausible strings) over meaningless placeholders when the code branches on them | **warning** when placeholders skip branches |

## Faker and random data

| Rule | Severity hints |
|------|----------------|
| Use **randomized** data for **fuzz-style** exploration, property tests, or load sampling—not as the default for **unit** examples | **note** when randomness adds little beyond a fixed table |
| **Non-reproducible** failures from unseeded random are **harmful** for CI | **error** when faker/random has **no seed** in deterministic suites |
| **Seeded** randomness (global seed per test run or per test) balances variety and debuggability | **warning** when seed is not logged on failure |
| Separate **“deterministic suite”** from **“stochastic suite”** if both exist | **note** when mixing causes flaky classification |

## Parameterized tests

| Rule | Severity hints |
|------|----------------|
| Use **`test.each` / `@pytest.mark.parametrize` / theories** when the **same logic** applies to many inputs | **warning** when copy-pasted tests differ only by inputs |
| Keep the **data table readable**: short rows, clear headers, one logical dimension per table (or named tuples / small objects) | **note** when wide opaque tables obscure failures |
| Assertions should **pinpoint** which case failed (index, case name, input dump) | **warning** when failure output does not identify the row |

## File-based fixtures (JSON, YAML)

| Rule | Severity hints |
|------|----------------|
| Use **files** for **large or versioned** payloads (API golden files, complex documents), especially when **diffed** in review | **note** when inline would be worse |
| Avoid files for **small** data that fits inline—**file sprawl** is a maintenance burden | **warning** when indirection does not pay off |
| **Version** or **name** fixtures when the production schema evolves (`v2`, folder per API version); deprecate old fixtures deliberately | **warning** when one unmaintained golden rots |
| Keep **fixture location discoverable** (conventional folder, naming) | **note** when paths are ad hoc |

## Sensitive data

| Rule | Severity hints |
|------|----------------|
| **Never** use real **PII**, **secrets**, **API keys**, **tokens**, or production-like credentials in tests | **error** for real or realistic live secrets |
| Use **fake** or **generated** values; prefer **obviously fake** patterns where humans might skim (`test@example.invalid`) | **warning** when data looks like real identifiers |
| **Flag** hardcoded passwords/keys—even “dummy”—and prefer env or secret store fakes | **error** for credential-like literals; **warning** for plausible key material |

## Dates and times

| Rule | Severity hints |
|------|----------------|
| Use **fixed instants** in tests (`Instant.parse`, `new DateTime(2024, 3, 15, …)`), not **`new Date()` / `DateTime.Now`** as the only time source | **warning** when wall-clock bleeds into assertions |
| **Inject** or **mock** time providers / `IClock` / `time.Now` shim | **error** when flaky time boundaries (DST, midnight rollover) are likely |
| Be **timezone-aware** when production logic uses zones: specify offset or zone in data; avoid “server local” ambiguity | **warning** when tests assume implicit local TZ |
| For durations, control **monotonic** vs **wall** time if both matter | **note** when only wall time is mocked but timeouts use monotonic |

## Anti-patterns (flag explicitly)

| Anti-pattern | Typical severity |
|--------------|------------------|
| Shared mutable state across tests without isolation | **error** |
| Unseeded random/faker in deterministic CI | **error** |
| Real secrets or PII in repo | **error** |
| Empty or stringly mocks for structured contracts | **warning** |
| Giant shared fixture for trivial variation | **warning** |
| `new Date()` / `Now` in assertions | **warning** |
| No cleanup with shared persistent store | **error** |
| Copy-pasted tests that differ only by inputs (no parametrize) | **warning** |

## Severity guide

- **error**: Secrets/PII, broken isolation with persistence, invalid defaults that force hazard, unseeded random in suites meant to be deterministic.
- **warning**: Obscured intent, flaky patterns, vacuous mocks, missing timezone/clock control, maintainability hazards.
- **note**: Optional hardening, style preferences, documented trade-offs.

## Finding format (required)

For every issue:

```text
- severity: error | warning | note
- location: <file:line, test name, fixture path, or plan section>
- issue: <what violates which rule>
- suggestion: <concrete fix: inline, factory signature, seed, transaction, clock mock, parametrize table, fixture version>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Scope**: identify tests and helpers in plan or diff; list factories, fixtures, DB hooks.
2. **Visibility pass**: inline vs shared—does indirection earn its keep?
3. **Shape pass**: minimal fields, realistic mocks, factories with defaults/overrides.
4. **Isolation pass**: own data, uniqueness, transactions/cleanup/containers.
5. **Randomness pass**: seeded vs intentional fuzz; CI determinism.
6. **Table pass**: parametrize opportunities; readable rows.
7. **File pass**: golden/fixture necessity, versioning, discovery.
8. **Safety pass**: no secrets/PII; obvious fakes.
9. **Time pass**: fixed clocks, explicit offsets/zones.

For **review plan** mode, end with a short **recommended strategy** (bullets): defaults for data creation, isolation approach, time handling, and where parametrize/files apply.
