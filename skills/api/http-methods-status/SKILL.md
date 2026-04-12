---

## name: http-methods-status

description: >-
  Reviews REST APIs for correct HTTP method usage (GET/POST/PUT/PATCH/DELETE)
  and appropriate status codes. Use when reviewing API plans, OpenAPI specs,
  endpoint tables, or implementation (routes, controllers, handlers, diffs).
  Triggers: REST code review, HTTP semantics, idempotency, status codes, 201
  Location header, GET mutating state, POST for reads, API review agent.

# HTTP methods and status codes (REST review)

Apply when evaluating **endpoint definitions** or **implementation** against method semantics and response status conventions. Works in **review plan** (specs, docs, OpenAPI) and **review changes** (code, diffs).

## Operating modes


| Mode               | Typical input                                       | `location` field                              |
| ------------------ | --------------------------------------------------- | --------------------------------------------- |
| **Review plan**    | PRD, design doc, OpenAPI `paths`, endpoint matrices | Section, operationId, or `METHOD /path`       |
| **Review changes** | Diffs, route maps, controller/handler files         | `file:line` when visible; else `METHOD /path` |


If both exist, prioritize **changed** operations, then flag drift from the documented plan.

## HTTP methods


| Method     | Intended use                                                                                  | Checks                                                                                                                                                                |
| ---------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GET**    | Read-only; **safe** and **idempotent**; **no request body**                                   | **error** if handler mutates persistent state, creates side effects users rely on, or accepts a body. **warning** if naming/body suggests a write.                    |
| **POST**   | Create a resource or **trigger a non-idempotent process**                                     | **error** if used for a **read** or **full replacement** of a known resource (prefer GET or PUT). **warning** if POST is the only method and semantics are read-like. |
| **PUT**    | **Full** replacement of a resource; **idempotent**                                            | **warning** if docs/code treat it as partial update (prefer PATCH). Same state on repeated requests with same body.                                                   |
| **PATCH**  | **Partial** update; payload should contain **only changed fields** (or clear merge semantics) | **warning** if PATCH requires a full representation without justification.                                                                                            |
| **DELETE** | Remove resource; **idempotent**; **usually no request body**                                  | **error** if a body is required for standard delete-by-id. **note** if repeated DELETE returns 404—often acceptable.                                                  |


**Cross-cutting**: Flag **POST used for everything** when specific operations should be GET/PUT/PATCH/DELETE. Flag **GET that mutates** (logging-only is usually **note**, not **error**—use judgment).

## Status codes


| Code                          | When to use                                                         | Review notes                                                                                                                          |
| ----------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **200 OK**                    | Successful GET, PUT, PATCH, DELETE **with** a response body         |                                                                                                                                       |
| **201 Created**               | Successful POST that **creates** a resource                         | **error** if `Location` is missing **and** no clear client-visible URI in body (e.g. `id` + documented URL pattern—then **warning**). |
| **204 No Content**            | Successful DELETE or PUT/PATCH with **no** body                     | **warning** if 204 returns a body (invalid for strict REST clients).                                                                  |
| **400 Bad Request**           | Malformed request, failed **syntactic** validation                  |                                                                                                                                       |
| **401 Unauthorized**          | **Authentication** missing/invalid                                  | Name is historical; means *unauthenticated*.                                                                                          |
| **403 Forbidden**             | Authenticated but **not permitted**                                 |                                                                                                                                       |
| **404 Not Found**             | Resource **does not exist** (for that identifier)                   | **warning** if 404 masks **business rules** (e.g. "insufficient credits")—prefer403 or 422 with stable error contract.                |
| **405 Method Not Allowed**    | Path exists but **method** is wrong; include `Allow` when practical |                                                                                                                                       |
| **409 Conflict**              | State conflict: duplicate, version mismatch, conflicting write      |                                                                                                                                       |
| **422 Unprocessable Entity**  | **Semantic** validation failure (shape OK, meaning wrong)           |                                                                                                                                       |
| **429 Too Many Requests**     | Rate limiting / quota                                               |                                                                                                                                       |
| **500 Internal Server Error** | Unexpected failure                                                  | **error** if used for **expected** client errors or documented control flow.                                                          |


If the API uses **non-standard or rare** codes (e.g. `418`, custom `9xx`), use **warning** unless the spec justifies them.

## Anti-patterns (flag explicitly)


| Anti-pattern                                                         | Typical severity        |
| -------------------------------------------------------------------- | ----------------------- |
| **200 for errors** or uniform200 with error payload                  | **error**               |
| **404 for business logic** ("user not eligible", "order closed")     | **warning**             |
| **POST for obvious reads** (search, fetch-by-ids) when GET/HEAD fits | **error**               |
| **DELETE with request body**                                         | **error**               |
| **201 without `Location`** (and no equally clear URI story)          | **error** / **warning** |
| Obscure codes without rationale                                      | **warning**             |


## Severity guide

- **error**: Violates HTTP semantics, misleads clients, or breaks interoperability.
- **warning**: Suboptimal, inconsistent, or likely to surprise maintainers; fix before public v1 if easy.
- **note**: Trade-off, context-dependent, or minor documentation gap.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <endpoint METHOD /path, file:line, or plan section>
- issue: <what is wrong; cite method or status rule>
- suggestion: <concrete fix: method change, status mapping, header, or payload>
```

Order findings: **error** → **warning** → **note**. If clean, state that after a one-line summary of what was checked.

## Review procedure

1. **List operations** (method + path + brief purpose) from input.
2. For each operation, verify **method vs side effects** (read vs write, idempotency, body usage).
3. Trace **success and error responses** (status codes, headers—especially **201 + Location**, **204**).
4. Scan for **anti-patterns** and **status misuse** (404 for logic, 200 errors).
5. In **review changes**, prefer citing **lines** for new/changed handlers and route tables.

## Quick examples


| Situation                                    | Finding                                                                                                              |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `POST /users/search` with read-only body     | error: POST for read → `GET` with query or documented `POST` search only if bodies exceed URL limits (document why). |
| `GET /orders/{id}/cancel`                    | error: GET mutates state → `POST /orders/{id}/cancellation` or `POST /cancellations`.                                |
| Create user returns `201` without `Location` | error/warning: add `Location: /users/{id}` or document canonical URI in response.                                    |
| "Insufficient balance" returned as `404`     | warning: business rule → `403` or `422` with stable error type.                                                      |


## What this skill does not cover

URL path design, pagination formats, auth mechanism review, full OpenAPI style—only **verb semantics** and **status/header** appropriateness. Pair with URL-focused review skills when paths are also in scope.