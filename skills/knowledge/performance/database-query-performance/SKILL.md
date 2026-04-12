---
name: database-query-performance
description: >-
  Data-access and query performance knowledge: N+1 patterns, indexing, selective
  reads, pagination, join shape and cartesian explosion, ORM eager/lazy loading,
  raw SQL vs ORM trade-offs, and write amplification. Use when modeling queries,
  writing repositories, adding migrations, optimizing APIs backed by SQL/ORMs (EF Core, Hibernate, Django, SQLAlchemy, Prisma, Sequelize, etc.), or
  explaining why latency or DB load spikes.
---

# Database query performance

Reference for **how queries and ORMs behave at scale**. Adapt naming to your stack.

## Core principles

- **Round-trips dominate**: batching, projection, and join shape often matter more than micro-tuning a single statement.
- **Unbounded reads are a design bug**: pagination or streaming should be explicit on user-driven lists.
- **Caching does not fix unbounded or N+1 access** without a clear staleness and correctness story.

## Topics

### 1. N+1 patterns

- **Signals**: Loops with per-item DB calls; navigation properties accessed inside loops without batch load; GraphQL resolvers loading relations per parent.
- **Practices**: Eager load (join or split query), batch loader (DataLoader), or one projection query returning DTOs in one trip.

### 2. Indexes vs access patterns

- **Signals**: Filters, join keys, foreign keys, order/range predicates without supporting indexes; composite indexes where leading column doesn’t match predicates.
- **Practices**: Match index shape to dominant queries; consider covering indexes when justified; balance with write cost on hot tables.

### 3. Over-fetching (`SELECT *`, wide entities)

- **Signals**: Full rows when few fields needed; wide ORM entities on list endpoints; JSON/BLOB columns loaded unnecessarily.
- **Practices**: Projections, read models, DTO mapping, views for stable list shapes.

### 4. Unbounded result sets

- **Signals**: No `LIMIT` / keyset; `.ToList()` on large sets; APIs returning full collections.
- **Practices**: Default page sizes, max limits, keyset/cursor pagination to avoid huge offsets.

### 5. Join problems

- **Cartesian explosion**: missing join conditions, over-broad `FROM`, ORM include graphs multiplying rows.
- **Non-indexed join keys**: joins on computed or unindexed columns.
- **Practices**: Fix predicates; split queries (e.g. `.AsSplitQuery()` or equivalent) when includes multiply rows; batch related loads.

### 6. Raw SQL vs ORM

- **Signals**: Duplicate round-trips; dynamic SQL without parameters (security + plan churn); ORM client evaluation or chatty updates.
- **Practices**: One clear style per bounded context where possible; parameterized raw SQL when ORM shape is wrong; verify generated SQL and plans.

### 7. Eager vs lazy loading

- **Signals**: Lazy proxies in serialization or loops; missing includes on hot paths; over-eager includes pulling huge graphs.
- **Practices**: Add/remove includes; filtered includes; split queries when appropriate.

### 8. Write amplification

- **Signals**: Full-row updates for one column; many dirty columns; periodic update-all-rows; per-row read-modify-write loops.
- **Practices**: Narrow `UPDATE`, bulk APIs, partial updates, or append-only/event patterns when suitable.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Unbounded reads/writes at scale; N+1 on hot paths; cartesian joins in production; no pagination on user-driven lists |
| **Medium** | Likely missing indexes for dominant filters; moderate over-fetch; fixable ORM chatter |
| **Lower** | Micro-optimizations; speculative indexes; `SELECT *` on tiny reference tables |

## Using this knowledge

Cite loops, queries, or schema assumptions when giving advice. If the schema is unknown, state **assumptions** (e.g. no index on `(tenant_id, created_at)`). Tie recommendations to **latency, DB load, cost, and lock time**.
