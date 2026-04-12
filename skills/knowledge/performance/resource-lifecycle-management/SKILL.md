---
name: resource-lifecycle-management
description: >-
  Resource lifecycle knowledge: releasing connections and handles, structured
  cleanup (`using`/`with`/defer), timeouts and deadlines, bounded queues and
  backpressure, pool sizing vs server limits, graceful shutdown and draining,
  retry vs circuit breaking, and background work tied to cancellation. Use when
  configuring clients and hosts, designing shutdown, or debugging leaks, stalls,
  and cascading failures (.NET, JVM, Go, Python, Node, Rust patterns).
---

# Resource lifecycle management

Reference for **who owns a resource, for how long, and how it fails and stops**.

## Core principles

- **One clear owner** per resource class (connection, client, channel) with scoped lifetime documented.
- **Acquire/release in structured blocks** so early return and exceptions still release.
- **Shutdown is part of the feature**: drain, cancel, then dispose pools and clients.

## Topics

### 1. Leaked resources

- **Signals**: Sockets/streams/clients created per request without disposal; DB connections not returned; FFI handles without matching free; maps holding clients forever.
- **Practices**: `using` / `with` / try-with-resources / owned wrappers; DI-managed singletons with process-level disposal.

### 2. Cleanup on all paths

- **Signals**: `return` before `close`; cleanup only on happy path; `await` after acquire without `try`/`finally`; nested acquire without reverse release order.
- **Practices**: `finally` / defer stack; language-native disposal; document acquire order to avoid deadlocks.

### 3. Missing timeouts

- **Signals**: HTTP/gRPC/DB/queue defaults infinite or very long; sockets without deadlines; commands with timeout 0 on hot paths.
- **Practices**: Per-dependency timeouts; overall request deadline; propagate `CancellationToken` or equivalent.

### 4. Unbounded queues

- **Signals**: Unbounded in-memory queues/channels; full stream `collect()` into lists; reactive pipelines without backpressure; unbounded goroutine/worker spawn.
- **Practices**: Bounded capacity, drop/shed policy at ingress, stream processing, metrics on depth and reject rate.

### 5. Pool misconfiguration

- **Signals**: Pool max << concurrency → contention; pool max >> server capacity → storms; aggressive idle timeout → churn; per-request pool creation.
- **Practices**: Align replicas × pool with DB `max_connections` and burst; tune idle timeouts; measure under load.

### 6. Graceful shutdown

- **Signals**: Process exit without draining HTTP; consumers stop mid-batch; fire-and-forget on SIGTERM; health still “ready” while draining.
- **Practices**: Stop accepting, flip readiness, wait for in-flight with cap, flush publishers/consumers, close pools/channels; K8s `preStop` vs drain timing.

### 7. Retry without containment

- **Signals**: Tight retry on 5xx without breaker; very high max attempts; no jitter; retries multiply across layers.
- **Practices**: Retry budget, circuit breaker, bulkhead, backoff + jitter, idempotent writes, coordinated policy across tiers.

### 8. Orphaned background work

- **Signals**: `Task.Run` / `go func` / detached tasks without parent cancellation; timers after owner disposed.
- **Practices**: Structured concurrency, linked cancellation, task registry, cancel on dispose, `TaskGroup`/`WhenAll` patterns.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Leaks on hot paths; unbounded queue growth; no timeouts on critical deps; shutdown drops in-flight or leaks pools; retry storm risk |
| **Medium** | Cleanup only happy path; pool sizing likely wrong; missing backpressure; background work without cancellation |
| **Lower** | Extra defensive dispose; marginal tuning; documentation gaps with safe defaults |

## Using this knowledge

Quote acquire/release pairs, config keys, and host hooks. Tie **timeouts + retries + pool size + shutdown** when they interact. For singleton HTTP clients, still plan **dispose on exit** and handler/DNS lifetime (e.g. `SocketsHttpHandler`).
