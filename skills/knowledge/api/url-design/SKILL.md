---
name: url-design
description: >-
  Reviews REST API URL design for resource naming, URI hierarchy, path vs query
  parameters, and pluralization. Use when reviewing API plans, specs, OpenAPI
  paths, route tables, or code changes (framework routes, MapGet/MapPost,
  decorators, controller attributes). Triggers: REST URL review, URI design,
  endpoint naming, resource paths, nested routes, path parameters vs query
  string, API code review agent.
---

# REST API URL design (review agent)

Apply when evaluating **endpoint definitions** from a **plan/spec** or from **code/diffs**. Extract HTTP method + path template (+ param descriptions when present), then check rules below.

## Operating modes

| Mode | Input | Location field |
| --- | --- | --- |
| **Review plan** | PRD, design doc, bullet list, OpenAPI `paths`, tables | Section title, bullet, or path string |
| **Review changes** | Diff, route files, controllers, router modules | `path/to/file:line` when known; else route string |

If both exist, prioritize **changed** routes, then note drift vs the plan.

## Normalize first

1. Strip scheme, host, port. Strip a documented **base path** (e.g. `/api`, `/api/v1`) before counting segments—**rules apply to the resource path** the API owns. If the base is unclear, add a **note** stating the assumption.
2. Treat `{id}`, `:id`, and `{userId}` style placeholders uniformly for structure checks.
3. **Segment count** = path segments after the base, **including** `{param}` placeholders (e.g. `/users/{id}/orders` →3 segments).

## Rules

### Resource naming

| Expectation | Severity |
| --- | --- |
| **Nouns**, not verbs (`/users`, not `/getUsers`) | **error** if a segment is an obvious verb/command as a path segment (`get`, `list`, `fetch`, `create`, `delete`, `update`, `remove`, `save`, `submit`, `cancel`, etc.—especially as the **first** resource segment after base) |
| **Plural** collection roots (`/users`, `/orders`) | **error** if a collection segment is singular where a collection is meant |
| **Multi-word** segments: **lowercase + hyphens** (`/order-items`) | **error** for `camelCase` or `snake_case` in segments |

### URI hierarchy

| Expectation | Severity |
| --- | --- |
| **Nest** to show relationships (`/users/{id}/orders`) | Preferred pattern (no finding if correct) |
| **At most two relationship levels** under a root collection before favoring flatter resources + query filters (e.g. `/users/{id}/orders` OK; long chains like `/users/{id}/orders/{orderId}/line-items/...` → flatten to `/orders/{orderId}/line-items` or `/line-items?orderId=` as appropriate) | **warning** |
| **Deep paths**: more than **three** segments after the base (four or more) | **warning** (use **error** if nesting is redundant or unmaintainable) |
| **Implementation leakage** for IDs (docs or naming that expose auto-increment vs UUID strategy, or “database row id” as the public identity story) | **warning**; prefer opaque stable ids—if only numeric public ids exist, **note** to document stability and avoid enumerable scans |

### Path params vs query params

| Expectation | Severity |
| --- | --- |
| **Path**: resource **identity** and hierarchy (`/users/{id}`) | — |
| **Query**: filtering, sorting, searching, pagination (`/users?role=admin&sort=name`) | **warning** if optional filters are encoded as extra path segments (e.g. `/users/role/admin`) unless `role` is a deliberate first-class sub-resource |
| **Actions** in the path (`/users/{id}/activate`, `/orders/{id}/cancel`) | **warning**—treat as **controller-style**; acceptable only if **explicitly documented** as an exception; suggest `POST` on a noun sub-resource or command body on the resource |

### Anti-patterns (flag explicitly)

| Issue | Severity |
| --- | --- |
| Verbs in URIs | **error** |
| **Trailing slash** style mixed with no trailing slash (no documented convention) | **warning** |
| **File extensions** in paths (`/users.json`) | **error** |
| **Mixed pluralization** (e.g. `/user/{id}/orders`) | **error** |
| **Deep nesting** per hierarchy/segment rules above | **warning** / **error** |

## Finding format (required)

For every issue, output exactly:

```text
- severity: error | warning | note
- location: <endpoint, path template, or file:line>
- issue: <what violates which rule>
- suggestion: <concrete alternative path/query design>
```

Sort findings: **error**, then **warning**, then **note**. If there are no issues, state that clearly after a one-line summary of what was checked.

## Review procedure

1. **Enumerate** endpoints (method + path + optional param descriptions).
2. **Normalize** paths; count segments after base.
3. Per path: naming, pluralization, hyphenation, nesting depth, action segments, extensions, ID-leakage hints, path-vs-query misuse.
4. **Cross-endpoint** consistency: slashes, plural patterns, param naming style.
5. In **review changes** mode, prefer **file:line** from the diff or source; otherwise use the path template as `location`.

## Out of scope

HTTP method semantics (idempotency), status codes, auth, pagination standards, full OpenAPI validation—**URL structure and naming only**.
