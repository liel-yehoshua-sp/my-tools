---

## name: rest-api-url-design

description: >-
  Reviews REST API URL design—resource naming, URI hierarchy, path vs query
  params, pluralization, and common anti-patterns. Use when reviewing API plans,
  OpenAPI specs, route tables, or code changes (framework routes, attributes,
  MapGet/MapPost, Flask/FastAPI decorators, Spring mappings). Triggers: REST URL
  review, URI design, endpoint naming, API code review, resource naming, nested
  routes, path parameters vs query string.

# REST API URL design review

Apply this skill when the user wants endpoints reviewed against URL design rules, whether the input is a **plan/spec** (markdown, tables, bullets, OpenAPI excerpt) or **implementation** (diffs, route definitions, controller files).

## Operating modes


| Mode               | Typical input                                             | What to extract                                           |
| ------------------ | --------------------------------------------------------- | --------------------------------------------------------- |
| **Review plan**    | PRD, design doc, endpoint list, OpenAPI paths             | Path templates, described params, HTTP methods if present |
| **Review changes** | Diff, `Program.cs`, controllers, `*Routes`*, router files | Added/changed route strings and param bindings            |


If both exist, prioritize **changed** endpoints in review mode, then cross-check consistency with the plan.

## Normalization (do this mentally before rules)

1. Strip scheme, host, port, and optional **base path** (e.g. `/api`, `/api/v1`) for counting—**apply rules to the resource path** the team owns. If the base is ambiguous, state your assumption in a **note**.
2. Treat `:id` and `{id}` the same. Ignore query string for **path** rules unless the issue is mis-placed filters (see Path vs query).
3. One trailing slash on a path is **not** inherently wrong; flag **trailing slash inconsistency** only when the same API mixes styles (e.g. some routes with `/users` and others with `/users/` with no documented convention).

## Rules and severities

### Resource naming


| Rule                                                                                                | Severity                                                                                                                                                                                                  |
| --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Use **nouns**, not verbs (`/users` not `/getUsers`, `/orders` not `/deleteOrder`)                   | **error** for obvious verb-led segments (`get`, `list`, `fetch`, `create`, `add`, `update`, `patch`, `delete`, `remove`, `save`, `submit`, `cancel`, `activate` as the **first** path segment after base) |
| Collections use **plural** nouns (`/users`, `/orders`)                                              | **error**                                                                                                                                                                                                 |
| Multi-word resources: **lowercase + hyphens** (`/order-items`, not `/orderItems` or `/order_items`) | **error** for camelCase or snake_case in path segments                                                                                                                                                    |
| Avoid **file extensions** in paths (`/users.json`)                                                  | **error**                                                                                                                                                                                                 |


**Note**: Sub-resource segment names should still be nouns (`/activation` preferred over repeating verb style); see Actions.

### URI hierarchy and nesting


| Rule                                                                                                                                                                                                                                           | Severity                |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| Nest to show ownership/relation (`/users/{id}/orders`)                                                                                                                                                                                         | — (pattern to prefer)   |
| Avoid **deep** hierarchies: prefer **at most 3 path segments** in the resource path (after base) when counting **all** segments including `{param}` placeholders. **4+ segments** → **warning** (or **error** if extreme or redundant nesting) | **warning** / **error** |
| Prefer **no more than two nested relationship levels** under a root collection: e.g. `/users/{id}/orders` OK; `/users/{id}/orders/{id}/line-items` → prefer flatter `/orders/{orderId}/line-items` or **query filters**                        | **warning**             |
| **Mixed pluralization** on collection segments (e.g. `/user/{id}/orders` with singular `user`)                                                                                                                                                 | **error**               |


### Implementation leakage (identifiers)


| Rule                                                                                                                                                  | Severity    |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| Docs or paths that expose **internal** ID strategy in a leaky way (e.g. docs say "auto-increment integer", or path param described as DB row id only) | **warning** |
| Prefer **stable, opaque** resource identifiers in public APIs; if only numeric ids exist, suggest documenting stability and avoiding enumerable scans | **note**    |


### Path params vs query params


| Rule                                                                                                     | Severity                                                                                                                                                          |
| -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Path**: resource **identity** and hierarchy (`/users/{userId}`, `/orders/{orderId}`)                   | —                                                                                                                                                                 |
| **Query**: optional **filtering, sorting, searching, pagination** (`/users?role=admin&sort=name&page=2`) | If filters are encoded as extra path segments (e.g. `/users/role/admin`), flag as **warning** to use query params unless `role` is a first-class sub-resource     |
| **Actions** in the path: verbs or command-style segments (`/users/{id}/activate`, `/orders/{id}/cancel`) | **warning** with text: acceptable only as a **documented controller-style exception**; prefer `POST` + noun (`/activations`) or domain command body on a resource |


### Anti-patterns (quick list)


| Issue                                                                   | Severity                                                          |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Verbs as path segments                                                  | **error**                                                         |
| Trailing slash **inconsistency** across endpoints                       | **warning**                                                       |
| File extensions in path                                                 | **error**                                                         |
| Mixed pluralization                                                     | **error**                                                         |
| Deep paths (4+ segments after base, or excessive relationship chaining) | **warning** (upgrade to **error** if unmaintainable or redundant) |


## Finding format (required)

For **every** issue, output one block with:

```text
- severity: error | warning | note
- location: <endpoint path template, file:line, or plan section>
- issue: <what violates which rule>
- suggestion: <concrete alternative path/query design>
```

Order findings: **error** → **warning** → **note**. If clean, say so explicitly after a brief checklist summary.

## Review procedure

1. **Enumerate** endpoints (method + path template) from the input.
2. **Normalize** paths per above.
3. For each path, check: naming, pluralization, hyphenation, depth, action segments, extensions, ID leakage hints.
4. Compare **cross-endpoint** consistency (slashes, plural patterns, param naming style).
5. In **review changes** mode, cite **file and line** when visible in the diff or file; otherwise cite the route string as `location`.

## Examples (expected findings)


| Path                                             | Finding                                                                            |
| ------------------------------------------------ | ---------------------------------------------------------------------------------- |
| `GET /getUsers`                                  | error: verb-led path → `/users` with optional `?filter=`                           |
| `GET /user/{id}/orders`                          | error: mixed plural → `/users/{id}/orders`                                         |
| `GET /order_items`                               | error: snake_case → `/order-items`                                                 |
| `GET /users/{id}/activate`                       | warning: action in path → `POST /users/{id}` with body or `POST /user-activations` |
| `GET /users/{id}/orders/{id}/items/{id}/details` | warning: too deep → flatten with top-level `/order-items` or `/items` + query      |


## What this skill does not do

Does not replace security review, HTTP method semantics (idempotency), status codes, pagination standards, or full OpenAPI quality—only **URL structure and naming** for resources.