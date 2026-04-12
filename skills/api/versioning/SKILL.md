---
name: versioning
description: >-
  Reviews REST API versioning strategy (URL path, Accept header, query param),
  version numbering, backward-compatibility of schema and behavior, and
  deprecation hygiene. Use when reviewing OpenAPI/Swagger specs, API design
  docs, route modules, gateway config, or diffs for a public or multi-consumer
  HTTP API. Triggers: API versioning, v1 path, Accept vendor MIME, breaking
  changes, deprecation, Sunset header, backward compatibility, REST code
  review agent.
---

# API versioning and compatibility (review agent)

Apply when evaluating **how an API is versioned** and whether **changes preserve compatibility**—from a **plan/spec** (paths, headers, examples, changelog) or **code/diffs** (routes, filters, controllers, OpenAPI generators, gateway rules).

## Operating modes

| Mode | Typical input | `location` field |
| --- | --- | --- |
| **Review plan** | Design doc, ADR, OpenAPI `servers`/`paths`, tables of routes | Section title, `METHOD /path`, or header name |
| **Review changes** | Diffs, route files, middleware, contract tests, OpenAPI deltas | `path/to/file:line` when known; else `METHOD /path` or schema name |

If both exist, prioritize **changed** surfaces, then check **drift** vs the documented versioning policy.

## Detect signals (before judging)

Infer the **active** strategy from evidence; do not assume URL `v1` if headers contradict.

| Signal | Examples |
| --- | --- |
| **URL path** | First segment `v1`, `/api/v2/...`, route prefix `MapGroup("/v1")` |
| **Header** | `Accept: application/vnd.*.v1+json`, custom `API-Version: 1`, content negotiation docs |
| **Query** | `?version=1`, `?api-version=2024-01-01` |

**Unversioned**: no path segment, no documented version header/param, and base path is only generic (`/api`, `/`) with no compatibility story—**flag** for public or multi-consumer APIs.

**Mixed strategies**: same API surface uses more than one mechanism (e.g. some routes under `/v1` while others rely only on `Accept`, or query versioning alongside path `v2`)—**error** unless a **narrow, documented** exception exists (rare).

## Rules

### Versioning strategy

| Expectation | Severity |
| --- | --- |
| **Pick one** primary strategy and use it **consistently** API-wide: URL path (`/v1/users`), header (`Accept: application/vnd.myapi.v1+json` or team-standard header), or query (`/users?version=1`) | **error** if multiple strategies apply to different parts of the same API without documented rationale |
| **Query-param versioning** is **least recommended**—harder to cache, easier to omit, weaker client ergonomics | **warning** when chosen without justification |
| **No strategy** on an API described as **public**, **partner-facing**, or **multi-consumer** | **error** |
| **Internal-only** or **single known consumer** with a documented “move together” policy | **note** / **warning** instead of **error** only if that scope is explicit |

### Version numbering

| Expectation | Severity |
| --- | --- |
| Prefer **simple integer** API versions (`v1`, `v2`). Avoid **semver in the URL** (`/v1.2.3/users`) | **warning** for semver-in-path; **note** if semver appears only in **release** metadata, not routing |
| **Version the whole surface**—not different versions per endpoint in the same product API | **error** for per-endpoint version drift (e.g. `/users` on “v2” semantics while `/orders` still “v1” without namespaces) |
| **Skipped** major versions (`v1` → `v3`) | **warning** unless **changelog or doc** explains (sunset, internal-only `v2`, etc.) |

### Backward compatibility (contract and behavior)

When **review changes** or comparing **two spec revisions**, treat these as **breaking** unless paired with a **new API version** or a **documented, scoped exception** (e.g. beta-only audience).

| Change | Compatibility | Typical severity if done without a new version |
| --- | --- | --- |
| **Add** fields to **responses** | Backward-compatible | — |
| **Remove** or **rename** response fields | Breaking | **error** |
| **Add** **optional** request fields / parameters | Backward-compatible | — |
| **Make** a previously **optional** request field **required** | Breaking | **error** |
| **Change** field **types** (string ↔ number, enum membership reduction, format tightening) | Breaking | **error** |
| **Change** HTTP **status codes** for the **same** logical success/failure | Breaking | **error** |
| **Narrow** validation (stricter patterns, smaller ranges) | Often breaking | **warning** / **error** depending on client impact |
| **Change** error body **shape** or **codes** | Breaking for clients | **error** |

If the input is **only** a static spec with no “before,” flag **risk patterns** (required fields with vague evolution policy) as **note**/**warning** instead of asserting a breaking release.

### Deprecation

| Expectation | Severity |
| --- | --- |
| Deprecated routes/responses should advertise **`Deprecation`** and/or **`Sunset`** (or team-standard) response headers per [RFC 9745](https://www.rfc-editor.org/rfc/rfc9745) / [RFC 8594](https://www.rfc-editor.org/rfc/rfc8594) conventions | **warning** if deprecated in docs but **no** machine-readable header plan |
| Provide **migration** path: replacement endpoint/version, **changelog** link, or doc section | **warning** if missing |
| **Timeline**: sunset date or version removal window—avoid **indefinite** deprecation | **warning** if no sunset or removal milestone |
| Deprecated with **no replacement** documented | **error** when clients are still expected to migrate |

## Anti-patterns (flag explicitly)

| Issue | Typical severity |
| --- | --- |
| No versioning on **public** / **multi-consumer** API | **error** |
| **Mixed** URL + header + query versioning without clear rules | **error** |
| **Breaking** contract/behavior change **without** version bump | **error** |
| **Deprecated** endpoints with **no** sunset / removal plan | **warning** |
| **Per-endpoint** version mismatch within one API product | **error** |
| **Breaking** changes shipped as “minor” doc tweaks only | **error** |

## Severity guide

- **error**: Inconsistent or missing versioning where consumers will diverge; confirmed breaking change without new version; deprecated with no replacement.
- **warning**: Weak deprecation signaling, query versioning without rationale, skipped version unexplained, stricter validation likely to break clients.
- **note**: Documented single-consumer exception, acceptable additive-only release, or policy stated clearly in ADR.

## Finding format (required)

For every issue, output exactly:

```text
- severity: error | warning | note
- location: <endpoint, header name, schema field, doc section, or file:line>
- issue: <what violates which rule>
- suggestion: <concrete fix: unify strategy, bump version, add headers, document migration>
```

Sort findings: **error**, then **warning**, then **note**. If there are no issues, state that clearly after a one-line summary of what was checked.

## Review procedure

1. **Identify audience**: public, partners, multiple internal teams → stricter versioning requirements.
2. **Detect** versioning mechanism(s) from paths, `Accept` / custom headers, query params, gateway rules, OpenAPI `servers`.
3. **Consistency pass**: one strategy; integer major versions; no per-endpoint version soup.
4. **Compatibility pass** (when old vs new exists): responses, requests, types, statuses, validation tightness, error models.
5. **Deprecation pass**: headers, replacement, changelog, sunset/removal date.
6. **Summarize** residual risks (e.g. “additive-only policy not documented”) as **note**s.

## Out of scope

GraphQL schema deprecation rules, non-HTTP RPC versioning, database migration strategy, feature flags as a substitute for API versioning—**mention only** if they blur the API contract story.
