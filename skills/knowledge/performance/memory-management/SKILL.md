---
name: memory-management
description: >-
  Memory and retention knowledge: leaks (listeners, timers, subscriptions),
  unbounded in-memory structures, hot-path allocations, closure capture,
  string building, streaming vs full buffering, weak references, and
  disposal/finalization. Use when optimizing allocations, investigating OOM or
  growth, designing long-lived services or SPAs, or choosing APIs (pools,
  streams, builders) across JS/TS, .NET, JVM, Go, Python, Rust, native.
---

# Memory management

Reference for **retention, allocation pressure, and resource-like memory**. Adapt to runtime (GC’d vs manual).

## Core principles

- **Pair registration with teardown** for listeners, timers, and subscriptions on known lifecycles.
- **Bound in-memory queues and caches** or spill to external stores when scale is uncertain.
- **Prefer streaming** when input/output can exceed available RAM.

## Topics

### 1. Leaks: listeners, subscriptions, timers

- **Signals**: `addEventListener` / `on` / `subscribe` without remove; RxJS without `takeUntil` / teardown; `setInterval` without clear; .NET `event +=` without `-=`; observers on singletons.
- **Practices**: Cleanup in the same lifecycle hook (`useEffect` return, `IDisposable`, `defer`, `finally`, small RAII wrappers).

### 2. Unbounded collections

- **Signals**: Append-only lists/maps; in-memory queues without backpressure; global per-request maps; debug buffers; session dictionaries without TTL.
- **Practices**: Caps, eviction (LRU/TTL), ring buffers, bounded channels, spill to disk or external queue.

### 3. Large allocations in hot paths

- **Signals**: New large buffers/strings per request in tight loops; fresh serializer per call; LINQ/`map` materializing huge lists; boxing in hot loops; repeated parse of giant JSON.
- **Practices**: Pooling (`ArrayPool`, buffer reuse), `Span` / `stackalloc` where safe, structs, move work off hot path, reuse at service scope.

### 4. Closures holding references

- **Signals**: Lambdas capturing `this`, large graphs, or full HTTP context when only a small field is needed; long-lived tasks closing over UI graphs; static caches accidentally pinning user scope.
- **Practices**: Narrow DTOs into async work; copy primitives; weak refs for optional UI linkage where correctness allows.

### 5. String building in loops

- **Signals**: `+=` on strings in loops; repeated format building one giant string; SQL/log lines per row by concatenation.
- **Practices**: `StringBuilder`, `String.Join`, `bufio.Writer`, templates, buffer pools, structured logging.

### 6. Full-file / full-result buffering

- **Signals**: `readAll` APIs for large inputs; non-streaming `SELECT`; whole CSV/JSON/XML trees in memory; full HTTP bodies when streams suffice.
- **Practices**: Async streams, `IAsyncEnumerable`, pull parsers, DB cursors, NDJSON line-by-line.

### 7. Weak references (when appropriate)

- **Signals**: Caches that should not extend key lifetime; observer lists pinning subjects; parent/child graphs where strength is wrong.
- **Practices**: `WeakMap`/`WeakSet`, `WeakReference<T>`, `ConditionalWeakTable`, JVM `SoftReference` (with caveats), or TTL if weak breaks correctness.

### 8. Cleanup and finalization

- **Signals**: Native handles without deterministic close; `finalize`/`__del__` for correctness; swallowed cleanup exceptions; `IDisposable` never called; `Drop` doing blocking I/O.
- **Practices**: `using` / try-with-resources / `defer`; single owner for handles; avoid finalizers as primary release; document double-dispose safety.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Obvious leak on hot/long-lived path; unbounded growth on user input; large allocations per request at high QPS; native handle leaks |
| **Medium** | Likely retention under load; heavy warm-path allocations; missing unsubscribe on non-trivial lifetimes; read-all for potentially large inputs |
| **Lower** | Micro-optimizations; defensive weak refs; small string builds in rare code |

## Using this knowledge

Quote registrations without teardown, growing structures, or captures when diagnosing. Do not treat **manual GC** or finalizers as primary fixes without noting nondeterminism. When weak refs risk stale reads, call out **correctness vs retention**.
