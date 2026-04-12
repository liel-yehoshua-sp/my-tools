---
name: mocking-strategy-review
description: >-
  Evaluates use of mocks, stubs, spies, and fakes: test doubles taxonomy, over-
  and under-mocking, boundary placement (ports/adapters), realistic setup and
  types, DI vs module mocks, partial mocking risks, framework pitfalls (Jest,
  Vitest, Sinon, testdouble), verification discipline, and time/randomness
  control. Use in review plan mode to assess a described mocking strategy, or
  in review changes mode to audit actual test/double code. Triggers: mock
  review, stub spy fake, jest.mock, jest.spyOn, over-mocking, integration vs
  unit test boundaries, test double, sinon, testdouble, fake timers, mock
  verification, toHaveBeenCalledWith.
---

# Mocking strategy review

Apply when evaluating **how tests isolate dependencies**—from **plans** (described approach, ADR, “we’ll mock X”) or **implementation** (test files, factory doubles, module mocks).

## Operating modes

| Mode | Typical input | `location` field |
|------|---------------|------------------|
| **Review plan** | Test strategy notes, layering diagram, “unit vs integration” split, list of collaborators to fake | Area, layer, or doc section |
| **Review changes** | Diffs, `*.test.*`, `__mocks__`, setup files, DI wiring | `file:line`, test name, or `describe` block |

**Review plan**: judge whether the proposed doubles match the risk (I/O vs pure logic), boundaries (ports vs internals), and test pyramid; flag missing integration coverage or mock-the-world plans.

**Review changes**: cite concrete violations (wrong double type, boundary leaks, brittle verification, unrealistic stubs).

If both exist, prioritize **changed** tests and their doubles, then **shared** test setup they rely on.

## Test doubles: when to use which

| Double | Role | Prefer when |
|--------|------|-------------|
| **Spy** | **Observes** real or partial behavior; records calls/args without replacing the whole collaborator | You need **call evidence** on a real object, or to wrap one method while leaving the rest genuine |
| **Stub** | **Controls outputs** (return values, resolved promises, thrown errors) | You need **deterministic branches** and do not care about interaction order beyond what the scenario requires |
| **Mock** | **Verifies behavior**—expected calls, cardinality, arguments (often pre-programmed) | A **contract** between SUT and collaborator must hold (e.g. “must notify once with this payload”) |
| **Fake** | **Working lightweight impl** (in-memory repo, fake clock, stub HTTP server) | Real behavior is **expensive or broad**, but a **realistic subset** is valuable (state, validation rules) |

**Rules**

| Rule | Severity hints |
|------|----------------|
| Prefer **fakes** over deep stub trees when **stateful** behavior matters (ordering, uniqueness, persistence semantics) | **warning** when many chained stubs simulate what a small fake would model clearly |
| Prefer **stubs** for **data setup**; use **mocks** when **outbound interaction** is the behavior under test | **note** when mock expectations assert data-only calls that stubs would cover |
| Use **spies** to **observe** without reimplementing the collaborator | **warning** when a full mock duplicates spy + stub unnecessarily |

## Over-mocking

| Rule | Severity hints |
|------|----------------|
| Tests should assert **observable behavior** of the SUT, not **how** it reaches that outcome through private collaborators | **warning** when expectations mirror implementation details that could change without user-visible impact |
| If **every** dependency is mocked, the test may only prove the SUT **calls** things—not that results are coherent | **warning** for “hollow” unit tests; suggest at least one **narrow integration** or **contract** test |
| **Do not mock what you do not own** without a seam: wrap third-party SDKs/clients behind an **adapter** and mock the **your** interface | **warning** when tests patch vendor globals or deep import paths |
| Mocking **framework** or **language** internals (module loader, timers) everywhere increases fragility | **note** when simpler injection or fakes would stabilize tests |

## Under-mocking (wrong layer for a unit test)

| Rule | Severity hints |
|------|----------------|
| **Unit** tests should not hit **real** DB, filesystem, network, or **external APIs** unless the test is explicitly an **integration** or **end-to-end** test | **error** when CI unit job triggers real I/O without isolation |
| File or socket I/O in “unit” suites: prefer **fakes**, **in-memory** stores, **record/replay**, or **move** to integration suite with containers | **warning** when slowness/flakes imply wrong layer |
| **Golden rule**: if failure needs **external uptime** or **shared env**, it is not a pure unit test | **note** when naming/CI job should reflect integration |

## Mock boundaries

| Rule | Severity hints |
|------|----------------|
| Mock at **architectural boundaries** (hexagonal **ports**, **facades**, **repositories**, HTTP/email clients), not **deep private** helpers of the SUT | **warning** when tests reach into module-private functions to stub |
| Double the collaborator’s **public contract** (methods the SUT actually calls), not **internal** methods of the same class under test | **error** when partial mocks on SUT internals replace refactoring |
| **Stable** seams (constructor-injected interfaces) beat **import-time** patches for maintainability | **warning** when brittle `jest.mock` path coupling blocks refactors |

## Mock setup correctness

| Rule | Severity hints |
|------|----------------|
| Stubs must return **realistic** shapes: required fields, nesting, and **types** the production code reads | **warning** for `{}`, `true`, or `null` that skip validation/branches |
| Mocked **return types** and **promise** shapes must match **real** signatures (sync vs async, array vs single) | **error** when tests pass but production would throw on shape |
| **Reset** doubles between tests (`afterEach` clear mocks, restore spies, sinon sandbox, fresh instances) | **error** when leaked state causes order-dependent failures |
| Shared `beforeAll` mocks: ensure **no** cross-test mutation unless **immutable** config | **warning** when one test’s `mockResolvedValue` poisons the next |

## Dependency injection: trade-offs

| Approach | Good for | Risks |
|----------|----------|-------|
| **Constructor / function-parameter injection** | Explicit seams, **fast** unit tests, **no** import patching | Larger constructors; wiring in composition root |
| **Module-level mocking** (`jest.mock`, `vi.mock`, `proxyquire`) | Legacy code **without** seams; quick isolation | **Tight coupling** to module paths; hoist/order quirks; harder refactors |
| **DI container** (resolve in tests) | Apps already containerized; integration-style tests | **Hidden** dependencies; need **test-specific** registrations |

| Rule | Severity hints |
|------|----------------|
| Prefer **injection** for new code; reserve **module mocks** for boundaries you cannot inject yet | **note** when new code uses module mocks only for convenience |
| When using containers in unit tests, **register fakes** explicitly—avoid **implicit** prod bindings | **warning** when tests accidentally resolve real adapters |

## Partial mocking

| Rule | Severity hints |
|------|----------------|
| **`jest.spyOn` / `vi.spyOn` on the module-under-test** ties tests to **internal** structure; often breaks on extract/rename | **warning**; suggest moving logic behind injectable helper or pure function |
| Mocking **one method** of the **class under test** while running others is usually a **design smell** (SRP violation or missing collaborator) | **warning**; prefer splitting class or injecting the volatile part |
| Spying on **exported** helpers shared across modules can create **hidden coupling** | **note** when public API should expose the seam instead |

## Framework-specific pitfalls

| Framework | Common pitfalls |
|-----------|-----------------|
| **Jest** | `jest.mock` **hoisting**—cannot reference out-of-scope vars without `jest.requireActual` / factory patterns; **forgetting** `await` on mocked async; **not** using `resetModules` when tests need fresh module state; **`__esModule`** interop with Babel/TS |
| **Vitest** | `vi.mock` hoisting similar to Jest; **`vi.importActual`** for partial mocks; ensure **`pool`/threads** don’t share mutated singletons without isolation |
| **Sinon** | **Forgetting** `sandbox.restore()`; stubbing **already-spied** methods; **fake timers** + **async** without flushing promises (`clock.tickAsync` / `await` microtasks) |
| **testdouble** | **Replacing** modules vs **plain** objects—prefer `td.constructor` / `td.object` consistently; verify **arity** and **promise** return; avoid **verifying** incidental calls |

| Rule | Severity hints |
|------|----------------|
| Match framework **lifecycle** (restore, resetMocks, clearAllMocks) to **test runner** defaults | **warning** when project mixes patterns and leaks state |
| **Partial** `jest.requireActual` mocks: export maps must stay aligned or tests **lie** about prod | **warning** when mocked module surface diverges from real |

## Mock verification

| Rule | Severity hints |
|------|----------------|
| Assert **meaningful** interactions: **arguments** that matter for correctness, not **every** internal call | **warning** for noisy `toHaveBeenCalled` spam |
| Prefer **specific** matchers (`expect.objectContaining`, partial match) over **brittle** full-object equality when irrelevant fields fluctuate | **note** when tests break on additive fields |
| **Call order** assertions only when **order is part of the contract** (queues, locking, UI event sequencing) | **warning** when order is incidental |
| **Cardinality**: `toHaveBeenCalledTimes` when duplicates would be a bug; avoid redundant `called` + `times` without intent | **note** |

## Time and randomness

| Rule | Severity hints |
|------|----------------|
| Stabilize **wall time**: inject **clock** / `Date` supplier, or use **`jest.useFakeTimers()` / `vi.useFakeTimers()` / Sinon fake timers** when code uses `Date.now`, `setTimeout`, `setInterval` | **warning** when real time makes assertions flaky |
| After fake timers, **advance** time and **flush** promises/`act` as required by framework docs | **error** when async work never runs and tests pass vacuously |
| **`Math.random`**: **inject** RNG, **stub** with fixed sequence, or **seed**; document seed in failures | **warning** for uncontrolled random in deterministic unit suites |
| Prefer **one** strategy per test: mixing real and fake timers without clarity causes **ordering** bugs | **warning** |

## Anti-patterns (flag explicitly)

| Anti-pattern | Typical severity |
|--------------|------------------|
| Unit test hits real DB/network/filesystem/API | **error** |
| Mocks third-party SDK directly instead of owned adapter | **warning** |
| Stub returns empty/wrong shape vs production contract | **warning** / **error** if types lie |
| Expectations on private/internal call sequences | **warning** |
| No mock/spy reset; order-dependent tests | **error** |
| `spyOn` on module-under-test to “reach” private logic | **warning** |
| Asserting call order without contractual need | **warning** |
| Fake timers + async without flush/advance | **error** |
| Only mocks, no behavioral or narrow integration confidence | **warning** |

## Severity guide

- **error**: Real I/O in unit suite, wrong async/timer behavior hiding bugs, type lies that mask production throws, state leakage across tests.
- **warning**: Over-specified mocks, wrong test layer, brittle verification, partial mocks on SUT, mocking not-owned surfaces, vacuous stubs.
- **note**: Trade-off callouts (container vs inject), framework quirks worth documenting, optional fake vs stub consolidation.

## Finding format (required)

For every issue:

```text
- severity: error | warning | note
- location: <file:line, test name, plan section>
- issue: <what violates which rule>
- suggestion: <concrete fix: boundary move, fake, inject clock/RNG, reduce verification, integration test split>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Scope**: list collaborators, boundaries (ports), and test job type (unit vs integration).
2. **Taxonomy pass**: stubs for data, spies for observation, mocks for contracts, fakes for state—are choices coherent?
3. **Layer pass**: over-mock vs under-mock; any real I/O in unit path?
4. **Boundary pass**: doubles on public collaborator interfaces, not SUT internals.
5. **Setup pass**: realistic values, matching types, reset/isolation between tests.
6. **DI pass**: injection vs module mock vs container—appropriate for codebase age?
7. **Partial mock pass**: spies on SUT or one-method class mocks—smells?
8. **Framework pass**: hoisting, restore, fake timers + async correctness.
9. **Verification pass**: meaningful `toHaveBeenCalledWith`; order only if needed.
10. **Time/random pass**: clock and RNG controlled where non-determinism hurts.

For **review plan** mode, end with a short **recommended strategy** (bullets): which collaborators are faked vs stubbed, where integration tests live, boundary/adapters to introduce, and timer/RNG approach.
