---
name: integration-test-boundaries
description: >-
  Defines correct integration test boundaries and scope: unit vs integration vs
  e2e, pyramid compliance, real boundary crossing (HTTP, DB, queue, FS,
  externals), contract and module integration points, layered strategy  (controller/service/repository), scope creep, CI tagging/separation, and when
  not to add integration tests. Use in review plan mode to validate which
  integration points a plan should cover; in review changes mode to verify test
  categorization, naming, tags, and suite shape. Triggers: integration test
  scope, boundary tests, contract tests, test pyramid, unit vs integration,
  integration vs e2e, slice tests, API DB tests, test tagging, jest projects,
  describe.integration, wrong test layer, over-integration.
---

# Integration test boundaries and scope

Apply when deciding **what is an integration test**, **what it must exercise**, and **how it fits the pyramid**—from **plans** (test strategy, PR descriptions, ADRs) or **implementation** (test files, CI jobs, tags).

## Operating modes

| Mode | Typical input | `location` field |
|------|---------------|------------------|
| **Review plan** | Proposed test matrix, layers to cover, “we’ll add tests for X”, risk list | Section, story, or diagram reference |
| **Review changes** | New/changed `*.test.*`, `describe` blocks, CI config, test project splits | `file:line`, job name, or tag |

**Review plan**: map each change or risk to **one primary boundary** or **one bounded flow**; call out **missing** contract coverage and **miscategorized** layers.

**Review changes**: flag **mislabeled** tests, **all-mocked** “integration” tests, **e2e-shaped** integration tests, **pyramid** inversions, and **untagged** suites that block selective CI.

If both exist, prioritize **changed** tests and the **CI path** they run on, then **shared** fixtures.

---

## Unit vs integration

| Layer | Collaborators | What it proves |
|-------|---------------|----------------|
| **Unit** | Dependencies **mocked, stubbed, or in-process fakes** with **no real I/O** | **Logic and branching** in isolation; contracts **at the seam you own** (your interface), not the wire |
| **Integration** | **Real** components across **at least one** process/architectural boundary (see [Real boundaries](#real-boundaries)) | **Wiring, serialization, adapters, and collaboration** behave correctly together |

| Rule | Severity hints |
|------|----------------|
| Tests that **mock every** external boundary (DB client, HTTP, queue, FS) are **unit tests** even if the file says “integration” | **warning**—rename, move, or retag; fix CI job membership |
| Tests that hit **real** I/O but claim to be “unit” | **error** for CI/speed expectations; move to integration job or replace with fakes in unit job |
| **Unit** should cover **pure rules**, **edge cases**, and **error mapping** that do not need a real database | **note** when integration suite duplicates cheap unit coverage |

---

## Integration vs e2e

| Layer | Scope | Typical driver |
|-------|-------|----------------|
| **Integration (slice)** | **Bounded subsystem**: e.g. HTTP **or** message **→** app layers **→** real DB/cache/broker **as needed** | Test client, direct handler call, or **minimal** harness—**no** real browser UI driving the full product |
| **E2E** | **Full user journey** through **real UI** (or full external client chain) with **prod-like** environment | Browser automation, mobile driver, or **complete** external actor path |

| Rule | Severity hints |
|------|----------------|
| Integration tests must **not** require **browser UI** or **full-stack** “click through the product” unless explicitly classified **e2e** | **warning**—split API/service slice from UI journey |
| **One** integration test should **not** span **UI + all backends + email + billing**; that is **e2e** or **several** slices | **warning**—failure diagnosis and runtime cost suffer |
| Prefer **stable entry points** for slices (public API, queue consumer harness, CLI) over **incidental** UI coupling | **note** when plan ties backend-only risk to UI-only tests |

---

## Test pyramid compliance

**Expected ordering (count / runtime):** **unit ≫ integration > e2e**.

| Rule | Severity hints |
|------|----------------|
| Integration count **approaching or exceeding** unit count for the same module | **warning**—likely **logic in wrong layer** or **missing** unit tests |
| Integration tests used as **default** for **pure** functions or **trivial** mapping | **warning**—move to unit; keep **one** narrow slice if wiring is non-obvious |
| E2E used where a **slice** would catch the same defect | **note**—pyramid tilt; suggest bounded integration |
| **No** integration coverage for **high-risk** wiring (auth on API, migrations, idempotency, transactions) | **error** when only unit + e2e exist |

---

## Real boundaries

An **integration** test must exercise **at least one** **real** boundary:

- **HTTP** (inbound or outbound to real listener / test server on the wire)
- **Database** (real engine: local, container, or shared test instance—not an in-memory substitute **if** production semantics differ materially)
- **Message queue** (**publish and/or consume** against real broker or **contract-approved** test container)
- **Filesystem** (real FS when kernel/locking/atomicity matters; otherwise often **unit** with fake FS)
- **External service** (real sandbox/stage **or** **record/replay** / **wiremock** only when treated explicitly as **contract** tests—see below)

| Rule | Severity hints |
|------|----------------|
| **All** boundaries mocked → not integration | **warning** (“unit in disguise”) |
| Mocks **inside** the slice for **the boundary under test** → invalidates the integration goal | **error** for the stated boundary; narrow the claim or use real collaborator |
| Using **in-memory** DB when prod uses **different SQL/locking** without **also** a thinner **DB integration** check | **note**—document the gap |

---

## Contract boundaries

Identify **which contracts** need **integration** (or **contract**) tests—not only “happy path”:

| Contract | Typical integration focus |
|----------|---------------------------|
| **API ↔ consumer** | Request/response schema, status codes, auth, versioning, error envelope |
| **Service ↔ database** | Migrations, transactions, constraints, indexes, ORM mapping, raw SQL |
| **Service ↔ queue** | Serialization, headers, ordering, retries, dead-letter behavior |
| **Service ↔ external HTTP** | Timeouts, retries, auth handshakes—prefer **sandbox** or **hermetic** fake **documented** as contract baseline |

| Rule | Severity hints |
|------|----------------|
| Plan or suite **missing** integration for a **new** or **changed** contract surface | **warning** to **error** by blast radius |
| **Only** e2e covers a **critical** API/DB contract | **warning**—slow feedback; add slice |
| Contract tests **without** assertions on **schema/status/observable side effects** | **warning**—weak signal |

---

## Module integration

Beyond **external** boundaries, integration tests may target **two or more internal modules/services**:

- **Internal HTTP/gRPC/event** contracts between services owned by the team
- **In-process** modules: **domain ↔ adapters**, **handlers ↔ registries**, **event routing** between packages
- **Shared state**: caches, session stores, feature flags—when **real coordination** is the risk

| Rule | Severity hints |
|------|----------------|
| Prefer **unit** tests on each module **plus** **one** **narrow** cross-module test per **non-obvious** interaction | **note** when suite explodes pairwise combinations |
| **Circular** or **hidden** coupling only exposed by integration → add **targeted** test with **clear** failure message | **warning** if absent |

---

## Layered strategy (controller → service → repository)

| Combination | Usually **unit** | Usually **integration** |
|-------------|------------------|---------------------------|
| **Repository** | SQL/builder logic with **in-memory** or **mocked** driver | **Real** DB: CRUD, migrations, concurrency |
| **Service** | Rules with **faked** ports | **Service + real repo + real messaging** for **workflow** |
| **Controller / HTTP** | Serialization, status mapping with **mocked** app service | **HTTP stack + auth + filters + real app service + real DB** for **one** endpoint family |

| Rule | Severity hints |
|------|----------------|
| **Every** layer duplicated at full integration depth | **warning**—scope creep; pick **representative** routes |
| **No** integration at **outermost** slice but **many** repository-only integrations | **note**—may miss HTTP/auth/serialization defects |

---

## Scope creep

| Rule | Severity hints |
|------|----------------|
| **One** integration test should verify **one integration concern** or **one coherent flow** (given/when/then **one** primary defect hypothesis) | **warning** when name/assertions mix unrelated concerns |
| Large `beforeEach` **multi-route** setup shared by unrelated cases | **warning**—split fixtures/files |
| Assertions on **many** unrelated observables (DB row + email + metrics + log) without clear primary signal | **note**—split or prioritize primary effect |

---

## Tagging, naming, and CI separation

Integration tests should be **runnable separately** from unit tests:

| Mechanism | Examples |
|-----------|----------|
| **Metadata / tags** | `@Integration`, `describe.integration`, pytest marks, JUnit `@Tag("integration")` |
| **File/directory** | `*.integration.test.*`, `tests/integration/`, separate projects |
| **Runner config** | Jest/Vitest **projects**, Gradle **source sets**, .NET **Trait**/filters |

| Rule | Severity hints |
|------|----------------|
| Integration tests in **default** unit job | **error** when they need **infra** or **skew** runtime |
| **No** documented command to run **unit-only** locally | **note**—developer friction |
| Duplicate **overlapping** tags (`e2e` vs `integration`) for the same test | **warning**—define taxonomy |

---

## When **not** to write integration tests

| Situation | Prefer |
|-----------|--------|
| **Stable**, **well-unit-tested** code with **trivial** wiring | Unit only; occasional **smoke** slice if regression history warrants |
| **Third-party** behavior already validated upstream; **your** adapter is thin | Unit on **your** mapping; **optional** single sandbox ping, not a broad suite |
| **Read-only config** lookups with no boundary semantics | Unit with fixed config; **no** DB/integration |
| **Pure** transformations | Unit |

| Rule | Severity hints |
|------|----------------|
| New integration test adds **minutes** of CI for **no new boundary** | **warning** |
| **Redundant** integration **duplicates** unit without **new** risk | **note**—delete or demote |

---

## Severity rubric (default)

| Level | When |
|-------|------|
| **error** | Wrong CI layer (real I/O in unit job), mocks the boundary under claim, or missing coverage for **high-risk** new contract |
| **warning** | Miscategorized test type, pyramid tilt, e2e-shaped integration, scope creep, missing tags |
| **note** | Optimization opportunities, documentation gaps, acceptable trade-offs if explicitly documented |

---

## Output expectations

When reporting findings, for each item include:

1. **Rule** (short name)
2. **Severity**
3. **`location`** (plan section or `file:line` / test name)
4. **Fix**: rename/move/tag, split test, add slice, or **explicitly** document accepted gap

**TL;DR**: Integration tests **cross real boundaries** in a **bounded slice**, sit **between** unit and e2e in **count and scope**, prove **contracts** and **wiring**, stay **focused**, and run under **separate** CI from fast unit suites. Flag **miscategorized**, **all-mocked**, **UI-wide**, or **pyramid-inverting** tests—and **gaps** where contracts lack slice coverage.
