---
name: network-io-performance
description: >-
  Network and I/O knowledge: chatty APIs vs batching, blocking I/O in async
  stacks, compression, streaming vs full buffering, duplicate fetches, retry and
  backoff, connection pooling and keep-alive, and payload shaping. Use when
  designing service contracts, HTTP/gRPC clients and servers, BFFs, mobile
  backends, or debugging latency, tail behavior, and connection limits.
---

# Network and I/O performance

Reference for **round-trips, bytes on the wire, and client/server configuration**. Map signals to REST/GraphQL, gRPC, queues, browsers, and proxies.

## Core principles

- **Application batching beats transport tricks**: HTTP/2 multiplexing does not remove chatty domain APIs.
- **Bound memory on large bodies**: stream or page; avoid buffering entire downloads/uploads without limits.
- **Retries need budgets**: backoff, jitter, idempotency, and circuit breaking interact with timeouts and pools.

## Topics

### 1. Chatty APIs

- **Signals**: Sequential outbound calls where work is independent; per-item `await` loops to the same service; UI waterfalls (A then B then C).
- **Practices**: Aggregate read models, bulk RPC, batch routes, parallel `WhenAll`/`Promise.all` **when** ordering, rate limits, and server capacity allow.

### 2. Missing batch or bulk contracts

- **Signals**: Only single-resource routes while clients need many ids; repeated creates that could be bulk; one message per publish call.
- **Practices**: Define max batch size, partial failure semantics, idempotency for bulk writes; server-side fan-in where appropriate.

### 3. Blocking I/O in async contexts

- **Signals**: `.Result`, `GetAwaiter().GetResult()`, blocking stream reads on pool threads; sync HTTP in `async def`; JDBC in async handlers.
- **Practices**: Async APIs and `await`, or isolated sync boundary with dedicated pool, documented thread cost, and backpressure.

### 4. Compression (gzip, brotli)

- **Signals**: Large JSON/HTML without `Content-Encoding`; large gRPC payloads without compression option.
- **Practices**: Server middleware or edge compression; precompressed static assets; threshold for small responses (CPU vs bytes trade-off).

### 5. Streaming vs buffering large responses

- **Signals**: `ReadAsStringAsync` / read-all for large downloads; giant arrays without pagination; full file in memory before send.
- **Practices**: Chunked transfer, `IAsyncEnumerable`, fetch body streams, gRPC streaming, NDJSON; pair with backpressure.

### 6. Redundant fetches

- **Signals**: Duplicate GETs in one handler; per-component SPA fetches without coalescing; repeated metadata reads without request scope.
- **Practices**: Request-scoped memo, DataLoader, lifted parent fetch, BFF aggregation, client cache dedupe.

### 7. Retry and backoff

- **Signals**: No retry on transients; tight immediate retry; retry on non-idempotent POST without dedup; correlated retries after outages.
- **Practices**: Exponential backoff + full jitter, honor `retry-after`, Polly/resilience4j/SDK policies; retry only safe or idempotent operations; budgets and circuit breakers.

### 8. Connection pooling and keep-alive

- **Signals**: New `HttpClient` per call; short-lived clients; DB drivers without pool tuning; new broker connection per message.
- **Practices**: Shared client lifetime, `SocketsHttpHandler` lifetime (.NET), gRPC channel reuse, JDBC pool sizing, keep-alive configuration.

### 9. Oversized payloads

- **Signals**: Full entities when few fields needed; large blobs by default; verbose body logging; unpaginated list fields.
- **Practices**: Projections, sparse fieldsets, protobuf field masks, pagination, conditional GET with ETag.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Blocking hot async paths; unbounded in-memory bodies; retry storms; no pooling at high QPS; many sequential network calls on core latency path |
| **Medium** | Missing compression on large text/json; duplicate fetches; missing backoff; fixable chattiness or payload shape |
| **Lower** | Compression on tiny responses; speculative HTTP/2 talk; stylistic wrappers without measured pain |

## Using this knowledge

Prefer evidence: call chains, configs, sequence steps. Call out **interaction effects** (retry × timeout × pool). When suggesting parallelism, mention **throttling** and **server-side** limits.
