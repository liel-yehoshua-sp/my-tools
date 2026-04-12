---
name: concurrency-parallelism
description: >-
  Concurrency and parallelism knowledge: parallelizing independent async work,
  deadlocks and lock ordering, races and shared mutable state, synchronization
  granularity, blocking event loops and UI threads, pool exhaustion, cancellation
  and timeouts, and async pitfalls (fire-and-forget, sync-over-async). Use when
  implementing or refactoring async/threaded code, choosing parallelism limits,
  debugging hangs or races, or explaining behavior across stacks (JS/TS, Python
  asyncio, C#/.NET, Go, JVM, Rust, native).
---

# Concurrency and parallelism

Reference for **how concurrent systems behave** and **what patterns scale safely**. Adapt terminology to the language and runtime.

## Core principles

- **Structure concurrency**: bound fan-out, propagate cancellation, and aggregate errors intentionally.
- **Minimize shared mutable state**: prefer message passing, single writer, or immutable snapshots.
- **Never block the reactor/UI thread** on I/O or long CPU work without an explicit offload story.

## Topics

### 1. Sequential async that could run in parallel

- **Signals**: Independent I/O awaited one after another; `await` inside loops over independent items; waterfall calls with no data dependency.
- **Practices**: `Promise.all` / `Promise.allSettled`, `asyncio.gather`, `Task.WhenAll`, `join!` / `join_all`, structured concurrency (`TaskGroup`), bounded concurrency (semaphores, `p-limit`, `Parallel.ForEachAsync` with degree limit). **Caveat**: hidden ordering or session stickiness can make parallelization wrong—verify dependencies first.

### 2. Deadlocks (lock ordering, nested locks)

- **Signals**: Mutexes acquired in different orders across paths; lock held while awaiting I/O or user code; DB transactions locking resources in inconsistent order.
- **Practices**: Global lock order or single lock per subsystem; avoid holding locks across async suspension; document re-entrancy; timeout locks with clear retry policy where appropriate; shrink critical sections or use channels for handoff.

### 3. Races (unsynchronized shared mutation)

- **Signals**: Static/singleton/module-level mutation from concurrent tasks; read-modify-write on shared fields; non-concurrent maps written concurrently; check-then-act on shared state.
- **Practices**: `ConcurrentDictionary`, `sync.Map`, `Arc<Mutex<_>>` / `RwLock`, atomics for flags, message passing, or confine mutations to one thread (actor, queue dispatcher).

### 4. Over-synchronization

- **Signals**: One lock around unrelated work; coarse mutex serializing async gates; most pool threads waiting on one lock.
- **Practices**: Sharded locks, per-key locking, lock striping, copy-on-write; `ReaderWriterLockSlim` / `RwLock` on read-heavy paths; split data structures to reduce contention.

### 5. Blocking the event loop / main thread

- **Signals**: Sync file/network I/O on Node/browser main thread; `time.sleep` in async coroutines without executor; `.Result` / `.Wait()` / `GetAwaiter().GetResult()` on async code; heavy CPU on reactor thread; blocking HTTP clients inside `async def`.
- **Practices**: Async I/O end-to-end at boundaries; offload CPU to worker pools / `run_in_executor`; separate interactive vs batch paths.

### 6. Pool / scheduler exhaustion (unbounded fan-out)

- **Signals**: Unbounded `Task.Run` / `thread::spawn` / `go`; `Promise.all` over unbounded lists; unbounded `create_task`; goroutine leaks.
- **Practices**: Semaphores, bounded channels, bulkheads, batching, `MaxDegreeOfParallelism` / `max_workers`, queueing at ingress.

### 7. Missing cancellation / timeouts

- **Signals**: Long `fetch`, gRPC, DB, or sleep without `AbortSignal` / `CancellationToken` / `context.WithTimeout`; retries without overall deadline; daemons without shutdown.
- **Practices**: Wire tokens through; `AbortController`, `asyncio.wait_for`, context deadlines; linked `CancellationTokenSource`, `Task.WaitAsync` (where supported), or vetted timeout helpers.

### 8. Async misuse

- **Signals**: Fire-and-forget without error handling; `async void` (C#) outside UI handlers; unobserved task exceptions; sync-over-async in server code; non-awaited tasks from constructors.
- **Practices**: Structured concurrency or supervised background work; replace fire-and-forget with awaited flow or explicit registry + logging; `async Task` + `await`; bounded concurrent collectors in loops.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Data races on shared mutable state; lock ordering deadlock likely; unbounded fan-out; blocking only event loop thread on I/O; fire-and-forget dropping errors on payment/safety paths |
| **Medium** | Clear parallel win missed; missing cancellation on long calls; global lock on warm path; sync-over-async in handlers; pool exhaustion under plausible load |
| **Lower** | Micro-parallelism; defensive timeouts; minor contention; style-level improvements on cold paths |

## Using this knowledge

Prefer **evidence** (call chains, lock pairs, captures) when debugging. When recommending more parallelism, include **error handling** and **cancellation** for combined operations (`allSettled`, partial-failure policy). State assumptions when the threading model or workload is unclear.
