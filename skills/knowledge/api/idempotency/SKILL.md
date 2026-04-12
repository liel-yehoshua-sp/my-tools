---

## name: idempotency

description: >-
  Reviews REST APIs and handlers for idempotent HTTP semantics, Idempotency-Key
  usage on critical POSTs, safe client retry behavior, and race-safe key storage.
  Use when reviewing OpenAPI specs, API plans, payment/order/transfer endpoints,
  or implementation diffs for REST code review agents. Triggers: idempotency
  key, duplicate POST, safe retry, 5xx retry, idempotent GET PUT DELETE, PATCH
  semantics, financial API, REST code review, review plan, review changes.

# Idempotency and safe retries (REST API review)

Apply when evaluating **endpoint definitions** or **implementation** for **idempotent behavior**, **idempotency keys**, **retry safety**, and **concurrency correctness**. Works in **review plan** (specs, OpenAPI, ADRs) and **review changes** (handlers, middleware, storage, diffs).

Pair with [http-methods-status](../http-methods-status/SKILL.md) for verb/status baseline; this skill focuses on **repeat calls**, **deduplication**, and **client retry** contracts.

## Operating modes


| Mode               | Typical input                                                        | `location` field                              |
| ------------------ | -------------------------------------------------------------------- | --------------------------------------------- |
| **Review plan**    | OpenAPI, design docs, sequence diagrams, endpoint matrices           | `METHOD /path`, section, or `operationId`     |
| **Review changes** | Diffs, controllers, DB migrations, cache/key stores, client SDK docs | `file:line` when visible; else `METHOD /path` |


If both exist, prioritize **changed** operations that **mutate state** or **move money**, then scan for **undocumented** retry/idempotency behavior.

## Idempotent methods (HTTP semantics)


| Rule                                                                                                                                                                 | Severity hints                                                                                                                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GET** must be **safe** (no reliable side effects on resource state) and **idempotent**                                                                             | **error** if GET **mutates** persistent state users depend on (writes, deletes, state transitions). **note** for analytics/logging only when behavior is clearly non-authoritative. |
| **PUT** must be **idempotent**: N identical requests → same **resource state** as one; intended as **full replacement** of the representation                        | **error** if repeated PUT creates new resources or divergent state. **warning** if docs/implementations imply **partial** update (should be **PATCH**).                             |
| **DELETE** must be **idempotent**: repeat calls should **not** leave the system worse than the first success; **204** or **404** on subsequent deletes is acceptable | **error** if second DELETE returns **500** or other error solely because the resource is already gone (prefer **404** or **204** per documented contract).                          |
| **PATCH** is **not** inherently idempotent—do not assume it; JSON Merge Patch and custom semantics may or may not be idempotent                                      | **warning** if spec or docs **claim PATCH is idempotent** without defining merge/version rules.                                                                                     |
| **POST** is **not** idempotent by default—duplicates are expected unless deduplicated                                                                                | **note** for generic creates; see **Idempotency keys** for critical domains.                                                                                                        |


**Auto-generated fields** (e.g. `updatedAt`, `etag`, monotonic `version`): repeated PUT with the same body still yields **idempotent resource semantics** at the domain level—**do not** flag those fields alone as idempotency violations.

## Idempotency keys


| Rule                                                                                                                                                                                 | Severity hints                                                                                                                             |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| For **critical** **POST** operations (payments, orders, transfers, ledger entries, irreversible side effects), support an `**Idempotency-Key`** (or equivalent) request header       | **error** if such an endpoint lacks a documented/mechanized dedup story. **warning** if only client-side dedup with no server contract.    |
| Server **stores** the key scoped to the **account/tenant + endpoint** (or documented scope) and **replays the original success response** (including status and body) for duplicates | **error** if duplicates create **second side effects**. **warning** if behavior on duplicate is undefined in the API contract.             |
| Document **TTL** for stored keys (e.g. **24 hours**) and retention/error behavior after expiry                                                                                       | **warning** if TTL is missing from public docs. **note** if internal-only but stable.                                                      |
| Prefer returning the **same `201 Created` + same resource** for a duplicate key when the first request succeeded—**not** forcing `**409 Conflict`** unless conflict is real          | **warning** if duplicate key returns **409** while the first create succeeded and no true conflict exists—clients retrying may mis-handle. |


If the API uses a **non-standard** header or body field, treat it as acceptable when **documented consistently**; still verify **server-side** enforcement.

## Retry safety (client and infrastructure)


| Rule                                                                                                                                                | Severity hints                                                                                                                           |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Clients should be able to **retry** on **transport errors** and **5xx** without corrupting domain invariants when using **idempotent** methods      | **warning** if docs omit **which methods are safe to retry** and which require keys.                                                     |
| **Idempotent** endpoints must **not** create **duplicate** resources on retry (same identifiers, same outcome)                                      | **error** when retries observable as duplicate entities for GET/PUT/DELETE flows.                                                        |
| **POST** resource creation without **idempotency key** or other **natural dedup** (unique constraint + upsert, etc.) is risky for automated retries | **warning** for POST creates that **can** be retried by intermediaries without dedup. **error** for money movement without server dedup. |
| Document **at-least-once** behavior: what happens if the client never sees the response but the server committed                                    | **note** / **warning** when absent for critical POSTs.                                                                                   |


## Implementation concerns


| Rule                                                                                                                                           | Severity hints                                                                                         |
| ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Key handling must be **atomic**: **check-and-set** in one step (transaction, conditional write, compare-and-swap)—not **check-then-set** races | **error** if code path suggests two concurrent identical requests can both pass a **pre-insert read**. |
| Flag **race windows**: two workers both see "key missing" and proceed                                                                          | **error** for financial paths; **warning** elsewhere unless documented **serializable** isolation.     |
| Storage of idempotency records should survive restarts within the **TTL** window (or document loss and client behavior)                        | **warning** if only in-memory with no stated limitation.                                               |
| Returning **cached responses** should include consistent **headers** that matter to clients (within reason)                                    | **note** if `ETag`, pagination cursors, or rate-limit headers differ on replay without documentation.  |


## Anti-patterns (flag explicitly)


| Anti-pattern                                                                       | Typical severity        |
| ---------------------------------------------------------------------------------- | ----------------------- |
| **GET** with side effects that change **authoritative** state or user-visible data | **error**               |
| **DELETE** returns **500** for "already deleted"                                   | **error** / **warning** |
| **POST** payments/orders/transfers **without** idempotency key support             | **error**               |
| **PUT** used for **partial** update                                                | **warning** → PATCH     |
| Docs lack **retry** / **idempotency** guidance for a publicly integrated API       | **warning**             |
| Spec claims **PATCH** is globally idempotent                                       | **warning**             |
| Duplicate **Idempotency-Key** returns **409** though first request committed       | **warning**             |


## Severity guide

- **error**: Duplicate side effects possible, unsafe DELETE semantics, missing keys on money-critical POSTs, or clear race on key insert.
- **warning**: Gaps in docs, suboptimal status on replay, PATCH idempotency assumptions, PUT/PATCH confusion, ambiguous retry story.
- **note**: Acceptable trade-offs, logging-only GET side effects, or context-dependent client behavior.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <METHOD /path, file:line, or plan section>
- issue: <what is wrong; cite idempotency/retry rule>
- suggestion: <concrete fix: header, status, atomic storage, doc, or method change>
```

Order findings: **error** → **warning** → **note**. If clean, state that after a one-line summary of what was checked.

## Review procedure

1. **Inventory mutating operations** (POST/PUT/PATCH/DELETE and any GET that might write).
2. For **GET/PUT/DELETE**, verify **idempotency** and **safety** against the tables above.
3. For **POST**, classify **criticality** (payments, inventory, orders, transfers, irreversible workflows) and check **Idempotency-Key** (or equivalent) and **TTL** documentation.
4. Trace **implementation** for **atomic** key registration and **replay** of stored responses; look for **check-then-set** patterns.
5. Read **API docs** for **retry** guidance (which errors/methods are safe to retry, exponential backoff expectations if relevant).
6. In **review changes**, cite **lines** for new/changed handlers, middleware, and storage.

## Quick examples


| Situation                                          | Finding                                                                                                       |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `POST /payments` with no key mechanism             | error: add `Idempotency-Key`, atomic first-write record, replay stored response; document TTL.                |
| Second `DELETE /items/{id}` returns `500`          | error/warning: return `404` or `204` per contract; do not surface server error for missing resource.          |
| OpenAPI describes `PATCH` as "idempotent always"   | warning: narrow claim—define merge strategy and concurrency (ETag/version).                                   |
| Handler: `if (!exists) insert` without transaction | error: race—use unique constraint + catch conflict or single atomic upsert; ensure one wins for the same key. |
| Duplicate key returns `409` after successful `201` | warning: return same `201` and body as first response for safe client retries (unless true domain conflict).  |


## What this skill does not cover

Full **auth**, **URL design**, **pagination**, or **error body** shape—only **repeat-request** behavior and **deduplication**. Use dedicated skills for those topics.