---
name: caching-strategy
description: >-
  Application-level caching knowledge: what to cache, keying, TTL and eviction,
  invalidation, stampede mitigation, multi-layer consistency, cache-aside vs
  write-through vs write-behind, and safety (tenant isolation, unbounded growth).
  Use when designing or implementing caches (in-process, Redis/Memcached, ORM
  second-level, memoization), debugging staleness or memory growth, or discussing
  caching trade-offs. HTTP/CDN caching may overlap REST skills; this skill centers
  on app and distributed caches and how they compose with other layers.
---

# Caching strategy (application-level)

Use this skill as **reference knowledge** when reasoning about caches—not only when auditing code. Map signals to the stack (Redis, MemoryCache, Guava, Caffeine, Spring Cache, ASP.NET `IMemoryCache` / `IDistributedCache`, `cachetools`, etc.).

## Core principles

- **Define freshness per consumer**: strong vs eventual consistency, acceptable staleness, and read-your-writes expectations before choosing a pattern.
- **Key design is part of the security model**: shared caches must include tenant/user dimensions where data is scoped; never rely on cache alone for authorization.
- **Capacity is explicit**: TTL, max size, eviction, and key cardinality—especially for derived and negative caches.

## Topics

### 1. Repeated expensive work (where caching helps)

- **Signals**: Stable-input reads or aggregations on every request; remote calls (DB, gRPC, HTTP) with repeatable keys; heavy serialization or graph builds; dashboards recomputing from raw facts.
- **Practices**: Name hot paths and inputs that define entries; choose **per-process vs shared** boundary; set **TTL** or **event-driven** invalidation; document SLO for freshness.

### 2. Invalidation and staleness

- **Signals**: Writes without version bump, key delete, or purge event; infinite TTL on mutable entities; cache filled from eventually consistent sources without max staleness or read repair.
- **Practices**: Maintain an **invalidation matrix** (which mutations affect which keys/prefixes/tags); tie each write path to invalidation or **versioned keys**; for read-after-write, use write-through, primary read, or canary read where needed.

### 3. Over-caching (when not to cache)

- **Signals**: Trivial pure functions; tiny objects with huge key cardinality; multiple layers around microsecond work; serialization cost exceeds recomputation.
- **Practices**: Challenge ROI (latency saved vs ops burden and failure modes); remove cache, inline, or collapse layers; fix query shape or batching if I/O shape is the real cost.

### 4. Unbounded growth

- **Signals**: Unbounded `map`/Redis keys without TTL; “cache everything”; unbounded tag sets; negative caching without TTL.
- **Practices**: **TTL**, **max size** + eviction, probabilistic early expiry, or explicit size accounting; watch **per-request unique keys** (key explosion).

### 5. Cache stampede / thundering herd

- **Signals**: Many concurrent misses recompute the same key on expiry or cold start; no single-flight or per-key mutex.
- **Practices**: **Single-flight**, lease/mutex + jitter, probabilistic early refresh, or background refresh before TTL wall; coalescing loaders (`groupcache`-style, library `get(key, loader)` with stampede protection).

### 6. User- or tenant-specific data in shared caches

- **Signals**: Keys built only from resource id without tenant/user; PII or authz-gated payloads in global cache; cross-layer “public” caching of personalized responses.
- **Practices**: Namespace keys per tenant; keep object-level authz after cache hit; include tenant id, user id, or capability hash in keys—or use private per-process cache where appropriate.

### 7. Inconsistent cache layers (L1 + L2)

- **Signals**: In-memory + Redis without coordination; per-pod divergence; invalidation clears only one layer; rolling deploys with divergent local state.
- **Practices**: Short L1 TTL + version in key, invalidate broadcast, or **L1 only for immutable** facts; document staleness window across instances.

### 8. Cache-aside, write-through, write-behind

- **Cache-aside**: Read cache, on miss load store, populate. **Risk**: races on populate; stale until TTL/invalidation.
- **Write-through**: Update store and cache synchronously. **Use** when read-after-write must be fresh.
- **Write-behind**: Buffer in cache, async flush. **Rare**; needs durability and replay.
- **Signals of mismatch**: Strong consistency reads after cache-aside without invalidation; write-through on very hot writes without batching; write-behind without crash safety.
- **Practices**: State consistency tier per aggregate; centralize populate; transactional outbox for invalidation; primary read on critical paths when needed.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Cross-tenant or cross-user leakage; unbounded memory; strong consistency violated on money/safety paths; stampede likely to overwhelm dependencies |
| **Medium** | Missing invalidation for mutable data; hot-path stampede without mitigation; L1/L2 drift without bound; wrong pattern for read-your-writes |
| **Lower** | Micro-TTL tweaks; optional single-flight on low-QPS; documentation gaps where behavior is acceptable |

## Using this knowledge

Apply concepts to **designs, code, configs, and incidents**. When comparing options, cite trade-offs (staleness, correctness, memory, operability). When evidence is incomplete, state assumptions. Structured findings are optional; prioritize clarity and actionable patterns over a fixed audit template.
