---

## name: architecture-testability

description: >-
  Assesses code and plans for testable architecture: dependency injection, pure
  vs effectful code, side-effect boundaries, coupling/cohesion, test seams,
  interface segregation, statics/singletons, global state, config/env handling,
  and async structure. Primary lens for "review plan" mode; in "review changes"
  mode, ties findings to the diff. Use when reviewing plans, designs, refactors,
  PRs, or when the user asks about testability, test doubles, DI, isolating I/O,
  functional core, or making code easier to unit test.

# Architecture testability

Evaluate whether structure makes **fast, deterministic tests** easy: clear seams, minimal coupling, logic separated from I/O, and dependencies that can be substituted without heavy setup.

## Operating modes


| Mode               | Primary input                                                                                                | Focus                                                                                                                                                                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Review plan**    | Implementation plan, module layout, new types/services, task breakdown, dependency graph implied by the plan | Whether the **proposed** boundaries, ownership, and dependency direction support isolated tests. This skill is the **primary** testability lens for plan review—apply it in full before treating the plan as merge-ready from a testing perspective. |
| **Review changes** | Diffs, touched files, new public APIs                                                                        | **Design improvements** on changed code only: what would make *this* change easier to test (extract pure logic, inject collaborator, narrow interface, etc.).                                                                                        |


If both plan and code exist, **review changes** findings may reference plan intent; default scope is still the changed lines and their immediate design neighbors.

## 1. Dependency injection


| Look for                                                                            | Flag                          | Prefer                                                            |
| ----------------------------------------------------------------------------------- | ----------------------------- | ----------------------------------------------------------------- |
| `new ConcreteService()` inside business logic                                       | Missing seam                  | Constructor or factory injected; factory only at composition root |
| Imports used only to call **stateful** singletons (`getX()`, default export client) | Hidden dependency             | Pass `X` as parameter or constructor arg                          |
| **Law of Demeter** violations for testability (chains only to reach a collaborator) | Brittle, hard to fake         | Inject the needed capability directly                             |
| **Pure** helpers that take all data as arguments                                    | OK without DI                 | No change needed                                                  |
| Optional args used as **implicit** global config (`fetchImpl = globalFetch`)        | Works but obscures dependency | Explicit interface in signature or small options object           |


Call out **function parameters vs module imports**: parameters are explicit seams; module-level imports of concrete implementations usually are not (unless behind an interface and swapped in tests via loader/mocking policy).

## 2. Pure functions and functional core


| Signal                                    | Action                                                                                                      |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Branching/math/formatting mixed with I/O  | Extract **pure** `f(input) → output` (no I/O, no mutation of shared state, no clock/random unless injected) |
| Same logic duplicated to avoid extraction | Consolidate into pure function; test with table-driven cases                                                |
| Domain rules in handlers/controllers      | Move to **functional core**; keep **imperative shell** thin (parse → call core → map result → execute I/O)  |


Note: purity is **relative to** injected time/random/ID—pass them as arguments to keep core deterministic.

## 3. Side effect isolation

Treat as **edges**: DB, network, filesystem, message queues, process spawn, logging that affects behavior, ambient auth/session reads.


| Pattern                                                      | Concern                                                    |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| Business rule interleaved with `await client.` / `fs.` / SQL | Hard to unit test; split **decide** vs **act**             |
| Logging only for diagnostics                                 | Lower priority unless log side effects change control flow |
| Retry/backoff inside domain function                         | Extract policy or inject `sleeper`/`clock` for tests       |
| Transaction boundaries spanning unrelated rules              | Split or document; tests need smaller units                |


## 4. Coupling and cohesion


| Issue                                                                | Why it hurts tests                                 | Suggest                                                  |
| -------------------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------- |
| **High fan-in** “util” importing many domains                        | Any test pulls the world                           | Split by domain; invert dependency                       |
| **Circular** module/package deps                                     | Cannot compile or substitute one side in isolation | Introduce interface at cycle break; dependency inversion |
| **God class/module** (many reasons to change, many responsibilities) | Huge fixtures, flaky tests                         | Extract cohesive types; SRP                              |
| **Leaky abstraction** (concrete types in public API)                 | Consumers over-mock                                | Narrow interfaces                                        |


## 5. Seam identification

For each collaborator, state **where a test double can be inserted**:


| Seam type                   | Example                                | Test hook                                                                                          |
| --------------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Constructor injection       | `new Service(repo: IRepo)`             | Pass fake/stub `IRepo`                                                                             |
| Function / method parameter | `process(order, pricing: PricingPort)` | Pass stub `pricing`                                                                                |
| Module import               | `import { db } from './db'`            | Often requires loader mock or indirection—**flag** as weak seam unless project standard handles it |
| Environment variable        | `process.env.FEATURE_X` deep in logic  | Inject `Config` or feature flags                                                                   |
| Configuration object        | `config.apiTimeoutMs`                  | Pass explicit `config` into builder/service                                                        |


Prefer **constructor or parameter** seams for domain code; reserve env for true process-level concerns and compose them once at startup.

## 6. Interface segregation


| Smell                                             | Recommendation                                                       |
| ------------------------------------------------- | -------------------------------------------------------------------- |
| Depends on concrete class with 20 methods; uses 2 | Depend on **narrow** interface / protocol / trait                    |
| “Mock the whole ORM”                              | Introduce repository or query port with methods the use case needs   |
| Leaking DTOs from infrastructure into core        | Map to domain types at boundary; ports return domain-friendly shapes |


## 7. Static methods and singletons


| Case                                         | Severity | Suggest                                                                 |
| -------------------------------------------- | -------- | ----------------------------------------------------------------------- |
| Static **pure** math/string helpers          | Low      | Usually fine; still prefer instance if polymorphism needed              |
| Static **factory** with I/O                  | High     | Instance + injected dependency                                          |
| Singleton **lifecycle** owns connections     | Medium   | Injectable `ConnectionFactory` or explicit `open()` in composition root |
| Singleton **hides** branching used by domain | High     | Interface + inject; or pass result of `getInstance()` as parameter      |


Flag when **logic that needs tests** lives in static/singleton—those tests often require global reset or brittle ordering.

## 8. Global and module-level state


| Pattern                              | Risk                  | Mitigation                                     |
| ------------------------------------ | --------------------- | ---------------------------------------------- |
| Mutable module-level `let cache`     | Order-dependent tests | Move into class instance or explicit `Context` |
| Exported object mutated after import | Shared mutation       | Freeze, encapsulate, or factory per test       |
| Implicit **reset** in `afterEach`    | Fragile               | Prefer instance-scoped state                   |


## 9. Configuration and environment


| Smell                                               | Fix                                                      |
| --------------------------------------------------- | -------------------------------------------------------- |
| Magic numbers/strings for timeouts, URLs, limits    | Named config; inject or single validated config load     |
| `process.env` / `os.Getenv` scattered in call stack | Load once → typed `Config` → pass down or register in DI |
| **Silent defaults** in deep logic                   | Centralize defaults in config builder; document          |


## 10. Async boundaries


| Style                                      | Testability note                                                                      |
| ------------------------------------------ | ------------------------------------------------------------------------------------- |
| **async/await** with shallow stacks        | Usually easiest—await fake promises, control timing with injected clocks where needed |
| Flat promise chains                        | OK if narrow; avoid mixing uncaught error paths                                       |
| Deeply nested callbacks                    | Hard to read and test; refactor to async/await or named functions                     |
| **Fire-and-forget** tasks                  | Flaky tests; expose `Task`/handle or inject executor                                  |
| Hidden **concurrency** (background timers) | Inject scheduler or abstract `delay`                                                  |


## Severity guide

- **blocker**: No reasonable seam to substitute I/O or time; circular deps; domain correctness untestable without integration harness.
- **major**: Concrete wide dependencies; globals/statics holding logic; env reads in core.
- **minor**: Acceptable patterns with a smaller extract-DI refactor; style-level async cleanup.

## Finding format (required)

Use one block per issue:

```markdown
### <severity>: <short title>
- **Mode**: review plan | review changes
- **Location**: `<file:line>` or plan section / component name
- **Category**: DI | purity | side effects | coupling | seams | interfaces | static/singleton | global state | config | async
- **Observation**: what the code/plan does today
- **Test impact**: why tests are slow, flaky, or missing
- **Recommendation**: concrete structural change (extract X, inject Y, introduce port Z)
- **Seam** (if applicable): constructor | parameter | module import | env | config object
```

End with a **Summary**: top 1–3 actions that most improve testability for this plan or change set.

## Review plan — extra checklist

Apply when the user is validating an implementation plan (including alongside other plan-review skills):

- Each new module has a **single** primary responsibility and a clear **dependency direction** (no new cycles).
- Tasks that add I/O also specify **ports** or injectable collaborators—not only concrete clients.
- Critical rules have a **pure** function or domain object home in the plan, not only “inside the handler.”
- Test strategy mentions **unit** seams (not only E2E) for new domain logic.
- Config/feature flags appear as **explicit** inputs in the design, not ad-hoc env reads.

## Review changes — scope rule

Stay anchored to **changed** symbols and their direct call graph:

- Prefer suggestions that **reshape the delta** (what was added/modified), not a full-repo audit.
- If a pre-existing god object is **only imported** unchanged, note **blocked by existing design** and suggest a follow-up unless the change extends it materially.

