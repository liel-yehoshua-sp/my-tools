---
name: request-response-shape
description: >-
  Evaluates REST API request/response body shape, envelope consistency, field
  naming, JSON vs other content types, and PATCH vs PUT semantics. Use when
  reviewing OpenAPI specs, API design docs, example payloads, serializers/DTOs,
  controllers, or diffs for a JSON-first HTTP API. Triggers: response envelope,
  bare array responses, camelCase vs snake_case, unknown JSON fields, Content-Type,
  Accept negotiation, API payload review, REST body structure, code review agent.
---

# Request and response shape (REST review)

Apply when judging **request bodies**, **success payloads**, **serialization**, and **content negotiation**—from **plans/specs** or **implementation**.

## Operating modes


| Mode               | Typical input                                                       | `location` field                                             |
| ------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------ |
| **Review plan**    | OpenAPI `paths` / `components/schemas`, design docs, example JSON   | `METHOD /path`, schema name, or doc section                  |
| **Review changes** | Diffs, DTOs, serializers, controller actions, `Produces`/`consumes` | `file:line` when visible; else `METHOD /path` or schema name |


If both exist, prioritize **changed** operations and schemas, then check **cross-endpoint consistency** (envelope and casing).

## Response structure


| Rule                                                                                                                                           | Severity hints                                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Pick **one** envelope strategy and use it API-wide: e.g. `{ "data": ... , "meta": ... }`, or **consistently flat** resource objects            | **error** if some endpoints wrap and others return raw resources with no documented exception                                                |
| **Collection** success responses: expose the list **inside** a wrapper (e.g. `data: []` or `items: []`), not a **bare JSON array** at the root | **error** for `[ {...}, {...} ]` at top level when the API claims extensibility/versioning; **warning** if only some list endpoints are bare |
| **Single resource** responses: either a **flat object** at the agreed place (e.g. `data`) or the same wrapper as collections                   | **warning** if singletons and collections use different shapes without reason                                                                |
| **Never** return a bare primitive at the root (`true`, `"ok"`, `42`)—use a named key (e.g. `data`, `value`, or a small object)                 | **error** for bare primitives when the API is documented as JSON objects                                                                     |


**Meta / pagination**: If pagination or totals exist, prefer them **alongside** the collection inside the same wrapper (`meta`, `page`, etc.), not only in headers unless that is the documented standard.

## Request bodies


| Rule                                                                                                                                                                                                                | Severity hints                                                                                                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **POST**, **PUT**, **PATCH** that carry a structured body should document **`Content-Type: application/json`** (or the negotiated type) and match implementation                                                    | **error** if body is JSON in examples but handlers ignore `Content-Type` or accept ambiguous types without documentation                                            |
| **PUT** = **full** resource representation (replace semantics). Flag docs or handlers that imply partial update without merge/PATCH rules                                                                           | **warning** if PUT examples omit fields that would be cleared on replace but text says "update"                                                                     |
| **PATCH** = **partial** fields only. Flag PATCH schemas or examples that require the **full** object where optional fields are omitted                                                                              | **warning** (or **error** if clients must send complete objects to avoid data loss)                                                                                 |
| **No silent ignore**: if the server accepts a field in JSON, it should **apply** it, **validate** it, or **reject** the request (unknown field policy). Silently dropping client fields is an interoperability trap | **warning** for permissive deserializers with no `additionalProperties: false` / strict mode story; **error** if ignored fields change security or billing behavior |


## Field naming


| Rule                                                                                                                                    | Severity hints                                                                                                     |
| --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **One casing convention** API-wide: **camelCase** *or* **snake_case**—not mixed in the same API surface                                 | **error** for mixed casing across operations/schemas; **note** for legacy sub-resources if called out as exception |
| Prefer **clear** names: `createdAt` not `ca`; `userId` not `uid` unless `uid` is a domain term in docs                                  | **warning** for cryptic abbreviations without glossary                                                             |
| **Booleans** should read as predicates: `isActive`, `hasAccess`, `canEdit`—not nouns like `active` or `access` when they are true/false | **warning**                                                                                                        |
| **Timestamps** in string form: **ISO 8601** with **offset or `Z`** (timezone), not ambiguous local strings                              | **error** for naked `"2024-01-1510:00:00"` without offset; **warning** if only some timestamps omit timezone       |


## Content negotiation


| Rule                                                                                                                        | Severity hints                                                                                                             |
| --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| If multiple **response** formats exist, honor **`Accept`** (or document a single format only)                               | **warning** if `Accept` is ignored and clients can receive surprising types                                                |
| Default **success** bodies for typical REST JSON APIs: **`application/json`** with matching **`Content-Type`** on responses | **error** if JSON handlers return **`text/html`** or **`text/plain`** bodies for API routes without documented negotiation |
| Error payloads should still declare a **`Content-Type`** consistent with the error format (usually JSON for JSON APIs)      | **warning** if errors are HTML pages from a JSON API                                                                       |


## Anti-patterns (flag explicitly)


| Anti-pattern                                                                                      | Typical severity                                        |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Inconsistent envelope across endpoints                                                            | **error**                                               |
| Top-level **bare array** responses for collections                                                | **error** / **warning** (see rules)                     |
| Mixed **camelCase** / **snake_case** in one API                                                   | **error**                                               |
| **Unknown fields** accepted and ignored                                                           | **warning** / **error**                                 |
| JSON API returning **HTML** or **plain text** errors/success without negotiation                  | **warning** / **error**                                 |
| Response objects **nested deeper than three levels** without justification (arbitrary deep trees) | **warning**—suggest flattening, links, or sub-resources |


Count nesting from the **agreed payload root** (e.g. inside `data`), not from HTTP framing.

## Severity guide

- **error**: Breaks client expectations, blocks evolution (envelope, casing split, wrong content types), or risks silent data/security issues.
- **warning**: Inconsistent or brittle; should fix before external contract freeze or v1.
- **note**: Documented trade-off, internal-only surface, or optional hardening.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <METHOD /path, schema name, field path, or file:line>
- issue: <what violates which rule>
- suggestion: <concrete change: wrap array, rename field, strict schema, header, split resource>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Inventory** success and request schemas per operation (plan) or DTOs/handlers (code).
2. **Envelope pass**: same wrapper rules for list vs item vs errors? Any bare arrays or primitives?
3. **Method semantics pass**: PUT vs PATCH examples vs validation.
4. **Naming pass**: casing uniformity, booleans, timestamps.
5. **HTTP layer pass**: `Content-Type`, `Accept`, error body types.
6. **Depth pass**: deeply nested structures—flag without clear domain reason.

## What this skill does not cover

HTTP method choice, URL design, status codes, auth, pagination *algorithms*, or full OpenAPI style—only **payload shape**, **field conventions**, and **representation/content-type** fit. Pair with HTTP method/status and URL skills when those are in scope.
