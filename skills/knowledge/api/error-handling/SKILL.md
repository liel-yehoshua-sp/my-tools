---

## name: error-handling

description: >-
  Reviews REST API error responses for format, RFC 9457 (Problem Details)
  alignment, validation error structure, consistency across 4xx/5xx, safe
  production payloads, and actionable error granularity. Use when reviewing
  OpenAPI error schemas, API design docs, exception filters, problem-details
  middleware, controller/handler error paths, or diffs for a JSON-first HTTP API.
  Triggers: error response review, API error format, problem+json, validation
  errors 422, error envelope, REST code review agent.

# Error handling (REST API review)

Apply when evaluating **how an API represents failures**—from **plans/specs** (documented error models, examples, OpenAPI `responses`) or **implementation** (exception middleware, `Results.Problem`, `ProblemDetails`, RFC7807 serializers, framework error handlers, manual `Json()` error bodies).

## Operating modes


| Mode               | Typical input                                                            | `location` field                                                       |
| ------------------ | ------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| **Review plan**    | OpenAPI `responses` / `components/schemas`, error examples, ADR sections | `METHOD /path`, response code, schema name, or doc section             |
| **Review changes** | Diffs, global exception handlers, filters, per-endpoint error returns    | `file:line` when visible; else `METHOD /path` + status or handler name |


If both exist, prioritize **changed** error paths and schemas, then check **cross-endpoint** consistency with the documented contract.

## Error response format


| Rule                                                                                                                                                                                                       | Severity hints                                                                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Use **one** error schema API-wide for **all** JSON error responses (4xx and 5xx), unless a documented, narrow exception exists (e.g. OAuth error body on `/token`)                                         | **error** when shapes differ by endpoint with no documented reason                                                                                                           |
| **Minimum** useful shape includes a **machine-readable code** (string enum / stable identifier) and a **human-readable message** for logs and developer debugging                                          | **warning** if only HTTP status or only free-text message exists; **error** if clients cannot branch on anything stable                                                      |
| **Recommended baseline**: `{ "error": { "code": "...", "message": "..." } }` (or equivalent single top-level object with the same information—not necessarily this key name if Problem Details wins)       | **note** when a custom envelope is fine but should still expose `code` + `message` (or map them clearly from Problem fields)                                                 |
| **Preferred**: [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) Problem Details (`application/problem+json` or `application/json` with the same fields): `type`, `title`, `status`, `detail`, `instance` | **warning** if docs promise Problem Details but handlers return ad-hoc JSON; **note** if JSON API uses Problem fields **nested** under `error`—ensure docs and clients agree |
| `type` should identify the **class** of problem (URI); `title` is a short summary; `status` repeats the HTTP status; `detail` is safe, specific text; `instance` may identify the specific occurrence      | **warning** if `type` is missing or not stable across deployments; **warning** if `detail` is empty while `title` is generic                                                 |
| **Content-Type** for errors should match the body (`application/problem+json` or documented JSON error type)                                                                                               | **warning** if JSON errors omit a clear `Content-Type` or mismatch body                                                                                                      |


**Extensions**: `errors` for field-level validation (see below) may appear **alongside** Problem Details fields if the team documents the combined shape—flag **inconsistency** when some endpoints use extensions and others do not.

## Validation errors


| Rule                                                                                                                                                                    | Severity hints                                                                                           |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Invalid input should return **400** or **422** (per team convention) with a **list** of field-level issues, not a single opaque string                                  | **error** for validation failures returned as **500** or **200**                                         |
| Each item: `**field`** (JSON pointer or logical name), `**code`** (machine-readable), `**message**` (human-readable)                                                    | **warning** if any of the three is missing; **error** if only `"Bad Request"` with no field breakdown    |
| Example shape: `{ "errors": [{ "field": "email", "code": "invalid_format", "message": "Must be a valid email" }] }`—exact key names may vary if documented consistently | **warning** if field paths are ambiguous (`email` vs `body.email` vs `/email`) without a documented rule |


If the API uses **Problem Details** for validation, ensure `**errors`** (or registered extension) is still structured—not only a long `detail` string listing fields.

## Error consistency and safety


| Rule                                                                                                                                            | Severity hints                                                                                          |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **Every** 4xx and 5xx JSON response uses the **same** top-level error contract (envelope + Problem fields + extensions)                         | **error** on mixed shapes                                                                               |
| **Never** return a **plain string**, **HTML**, or **stack trace** body for a JSON API’s normal error path                                       | **error** for HTML/string bodies; **error** for stack traces in production responses                    |
| Do **not** leak **SQL**, **DB vendor messages**, **internal file paths**, **hostnames**, or **secrets** in `message` / `detail` / `errors`      | **error** for obvious leakage; **warning** for overly verbose upstream errors passed through            |
| **500** responses: **generic** client-safe text plus a **correlation ID** / **request ID** (header and/or body) for support and log correlation | **error** if 500 exposes internals; **warning** if trace ID exists only in logs and not in the response |


Distinguish **developer-facing** detail (in docs or non-prod) from **production** responses when reviewing; flag gaps if prod/stage behavior is not defined.

## Error granularity


| Rule                                                                                                                                                                          | Severity hints                                                                                                        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Prefer **specific** HTTP statuses where they carry meaning: **409** conflict, **422** unprocessable entity (when used), **429** rate limit, **401** vs **403** as appropriate | **warning** when everything is **400** or **500** without documented narrowing                                        |
| Distinct **failure modes** get distinct **error codes**—not one `INVALID_INPUT` for all validation and domain errors                                                          | **warning** when codes are too coarse for clients to handle; **note** when a single code is documented as intentional |
| Flag errors that are **too vague** for reliable client logic (e.g. `"Something went wrong"` with no code, no field, no retry/constraint hint)                                 | **warning**                                                                                                           |


## Anti-patterns (flag explicitly)


| Anti-pattern                                                               | Typical severity        |
| -------------------------------------------------------------------------- | ----------------------- |
| Different error JSON shapes per endpoint or per status band                | **error**               |
| Only human text, no machine-readable **code**                              | **warning** / **error** |
| Leaking stack traces, SQL, paths, or raw exceptions to clients             | **error**               |
| **200 OK** (or 2xx) with an error payload or `success: false`              | **error**               |
| No clear split between **client** errors (4xx) and **server** errors (5xx) | **warning**             |
| Rate limiting or conflict scenarios folded into generic **400**            | **warning**             |
| Validation failures as **500**                                             | **error**               |


## Severity guide

- **error**: Contract-breaking inconsistency, unsafe leakage, wrong status class (e.g. validation as 500), or success status with error body.
- **warning**: Harder for clients to integrate, vague codes, or missing recommended fields (correlation ID, field-level detail).
- **note**: Documented exception, framework default that matches team policy, or optional hardening.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <METHOD /path, response code, schema name, file:line, or handler>
- issue: <what violates which rule>
- suggestion: <concrete fix: schema change, middleware, status/code mapping, field errors shape>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Inventory** error responses: documented `responses` entries (plan) or handler/middleware branches (code).
2. **Schema pass**: one consistent error model? Problem Details fields present where claimed? `code` + `message` (or equivalent)?
3. **Validation pass**: 400/422 with structured `errors` array? No empty "Bad Request"?
4. **Safety pass**: no stacks, SQL, paths, or secrets in prod examples or code paths; 500 is generic + trace/correlation ID.
5. **Granularity pass**: status codes and error codes map to distinct failure modes; flag catch-all patterns.
6. **Cross-endpoint pass**: same `Content-Type` and shape for all JSON errors.

## What this skill does not cover

Authentication scheme design, full logging/observability strategy, business validation rules inside domains, or non-HTTP transports—only **HTTP JSON error representation**, **consistency**, and **client-safe granularity**. Pair with **http-methods-status**, **request-response-shape**, and **rest-api-url-design** when those dimensions are in scope.