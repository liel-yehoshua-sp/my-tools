---
name: unit-test-speed-ci-review
description: >-
  Reviews unit test execution speed and CI efficiency: unnecessary I/O, heavy
  setup/teardown, file-level and in-file parallelization, slow-test discovery,
  import and compilation overhead, watch-mode and CI caching/sharding, intentional
  integration-test isolation (in-memory DB, testcontainers), snapshot cost, and
  memory leaks. Use when reviewing test code, test config, CI workflows, or
  implementation plans for test strategy; triggers include slow tests, flaky CI,
  Jest, Vitest, pytest, test parallelization, test sharding, ts-jest, SWC, and
  "review plan" or "review changes" for tests.
---

# Unit test speed & CI efficiency review

Apply when the user supplies **tests, test config, CI workflow, or an implementation/test plan** plus a **mode**:

- **review plan**: Flag **architectural** choices that predict slow or hard-to-parallelize suites: reliance on real FS/DB/network in unit layers, shared mutable fixtures, monolithic test modules, compilation strategy for huge repos, missing sharding/caching story in CI.
- **review changes**: Point to **concrete** files, hooks, and tests with **measurable** performance issues (redundant I/O per test, `beforeEach` hotspots, serial-only patterns, expensive imports, giant snapshots, leak signals).

If the mode is omitted, **infer** it: RFCs/design docs/test strategy docs → **review plan**; diffs/PRs/config edits → **review changes**.

Adapt names to the stack (Jest, Vitest, Cypress component tests, pytest, JUnit, .NET test SDK, Go `testing`, etc.).

## 1. Unnecessary I/O

- **Signals**: Unit tests touching **real** filesystem (temp dirs without isolation, reading repo fixtures repeatedly), **real** DB connections, HTTP/TCP to external hosts, DNS, or cloud APIs without hermetic doubles.
- **review plan**: Require **layers**: pure unit (mocks/fakes) vs **bounded** integration (in-memory or containers). Ban implicit network from default unit path.
- **review changes**: Replace with mocks, spies, in-memory adapters, or move to a dedicated integration job with explicit resources.

## 2. Heavy setup / teardown

- **Signals**: **Expensive** work in `beforeEach` / per-test setup that **does not** need fresh state: app bootstrap, DB schema creation, large fixture parsing, `npm`/`docker` spawn, global config reload.
- **review plan**: Document which fixtures are **immutable** (safe for `beforeAll` / session-scoped fixtures) vs **mutable** (must reset per test).
- **review changes**: Move one-time setup to `beforeAll` / global setup; use **factory** functions with minimal defaults; prefer **in-transaction** rollback patterns for DB tests instead of full rebuilds.

## 3. Test parallelization (across files / workers)

- **Signals**: `maxWorkers: 1` (or pytest `-n 0` / serial CI) without justification; **shared** temp dirs, fixed ports, global singletons, or static mocks that leak across files; environment mutation (`process.env`, `import.meta`, timezone) not restored.
- **review plan**: Define **worker-safe** fixtures; avoid global state in modules under test; specify port **0** / ephemeral resources or per-worker isolation.
- **review changes**: Isolate state per worker (unique dirs, random ports, per-test env restore); remove accidental serial bottlenecks; tune `maxWorkers` / `pytest-xdist` to CPU.

## 4. In-suite parallelization (within one file)

- **Signals**: `describe.concurrent` / `test.concurrent` (Vitest) or pytest async concurrency where tests **mutate** shared references, clocks, or module cache; order-dependent tests.
- **review plan**: Forbid concurrent tests in suites with **shared** service instances unless documented immutable.
- **review changes**: Keep serial when sharing mutable instances; split files; duplicate cheap setup instead of sharing dirty singletons.

## 5. Slow test identification

- **Signals**: No timing visibility in CI; single long pole dominating wall time; timeouts set globally without catching regressions.
- **review changes / plan**: Use **verbose** / **per-test timing** reporters (Jest `--verbose`, Vitest `--reporter=verbose`, pytest `--durations`, custom reporters); add **per-suite** or **per-test** thresholds for critical paths; publish **slow-test lists** as CI artifacts; consider **quarantining** chronic slow tests behind a separate job.

## 6. Module import cost

- **Signals**: Top-level imports pulling **heavy** trees (ORM clients, SDKs, full app `server.ts`, large generated protos); side effects on import; barrel files that load the world.
- **review plan**: Keep **test entrypoints** thin; discourage importing production composition root from every unit test.
- **review changes**: **Dynamic import** inside tests that need the heavy module; **mock** subsystems at import boundary (`jest.mock`, `vi.mock`, pytest `monkeypatch` / local imports); split modules so tests import **narrow** surfaces.

## 7. Compilation overhead (TypeScript-heavy stacks)

- **Signals**: `ts-jest` type-checking **every** test run; no project-reference split; tests compiling duplicate graphs in monorepos.
- **review plan**: Choose **transpile-only** in watch/dev (`isolatedModules`, SWC/esbuild/Vite-based runners); use **project references** / incremental builds for large repos; separate **typecheck** job from **unit** job if it shortens feedback.
- **review changes**: Swap to **`@swc/jest`** / **Vitest** / **esbuild-jest** where appropriate; enable caching of transpile output in CI; align `tsconfig` for tests (`types`, `skipLibCheck` judiciously).

## 8. Watch mode optimization

- **Signals**: Full suite reruns on tiny edits; watchers chasing `node_modules` or build outputs.
- **review changes / plan**: Use **`--onlyChanged` / `--changedSince`** (Jest), Vitest related filtering, or affected-based runners; tighten **watchPathIgnorePatterns** / `.watchmanconfig`; combine with **Vitest** workspace projects for scoped reruns.

## 9. CI-specific optimizations

- **Signals**: One mega job; no **shard** indices; cold `node_modules` every run; tests run when **only docs** change; always running full integration matrix.
- **review plan**: Define **sharding** (`shard=1/4`), **merge-queue** strategy, and **cache** keys (deps lockfile, compiler outputs); path filters for jobs.
- **review changes**: Add **matrix shard** env; enable **dependency** and **build output** caches with correct invalidation; **`fail-fast`** where early signal matters; optional **skip** rules tied to diff scope (with safeguards for shared libs).

## 10. Intentional I/O (semi-integration)

- **When real I/O is intended**: Prefer **in-memory** equivalents (**SQLite `:memory:`**, **mongodb-memory-server**, embedded stores) for speed; use **testcontainers** when fidelity needs real services—accept startup cost but **reuse** containers across tests in a file/session per worker; avoid live calls to **shared** staging unless marked network integration.

## 11. Snapshot serialization cost

- **Signals**: Huge snapshots (whole HTML/JSON trees); frequent snapshot churn in PRs; slow stringify/compare on large objects.
- **review changes**: Replace with **targeted** assertions (`expect` on ids/keys); split snapshots per component; trim noise fields; keep snapshots **small** and stable.

## 12. Memory leaks & suite slowdown

- **Signals**: Later tests in a full run get slower; growing handles (servers, timers, listeners); unclosed DB pools; retained global caches from mocks.
- **review plan**: Require **`afterAll` / global teardown** hooks for servers and pools; document long-lived resources per job.
- **review changes**: Clear timers, dispose clients, `server.close()`, `jest.restoreAllMocks()` / `vi.unstubAllGlobals()` where appropriate; use runner **leak detection** where available (e.g. Jest `--detectOpenHandles`, experimental leak flags—**verify** runner support and version); split suites that **accumulate** process-wide state.

## Severity guidance

| Severity | When to use |
| ------------ | ----------- |
| **critical** | Real network/DB in unit path; shared mutable state breaking parallel runs; unbounded per-test full app boot; CI always full matrix with no caching—predicting **multi-minute** PR feedback or **flaky** parallel failures |
| **warning**  | Clear `beforeEach` → `beforeAll` win; missing mocks for I/O; `maxWorkers: 1` without reason; heavy top-level imports; large snapshots; missing teardown for servers/pools |
| **info**     | Micro-optimizations; marginal worker tuning; optional split of typecheck vs test jobs |

## Output format (required)

For **each** finding, output:

1. **Severity**: `critical` | `warning` | `info`
2. **Location**: **review changes** — file, symbol, line range or config key. **review plan** — layer (unit vs integration), CI stage, or plan section.
3. **Issue**: Pattern and **impact** (wall time, parallelism, flake risk, maintainer cost).
4. **Suggested fix**: Concrete remediation (hook move, mock boundary, runner flag, CI snippet pattern).

Optional: order by **impact** (time saved × frequency); cap long lists with top items.

## Execution notes

- Prefer **evidence**: quote the expensive hook, import, I/O call, or shared state.
- Separate **true unit** vs **integration** expectations; do not mock away what the test is supposed to prove—**relocate** the test to the right layer instead.
- When recommending **more parallelism**, mention **isolation** (ports, dirs, env) and **determinism** (clocks, random seeds).
- For **review plan**, tie recommendations to **CI graph** (which jobs run when, what caches, what shards).
