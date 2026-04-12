---

## name: pagination-filtering

description: >-
  Evaluates REST collection endpoints for pagination (cursor vs offset), query
  filtering, sorting, partial-response field selection, and related anti-patterns.
  Use when reviewing OpenAPI specs, API design docs, or implementation (controllers,
  repositories, ORM queries) for list/collection routes. Triggers: pagination,
  page size, cursor, offset limit, filter query params, sort order, sparse fieldsets,
  fields param, collection endpoint review, REST list API, code review agent.

# Pagination, filtering, and sorting (REST collection review)

Apply to **collection endpoints** (list resources, search, index) from **API specs** or **code**.

## Operating modes


| Mode               | Typical input                                                                 | `location` field                                                       |
| ------------------ | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Review plan**    | OpenAPI `paths` / `parameters`, design docs, example requests/responses       | `METHOD /path`, parameter name, response schema, or doc section        |
| **Review changes** | Diffs, controllers, services, repositories, query builders, route definitions | `file:line` when visible; else `METHOD /path` or handler/function name |


If both exist, prioritize **changed** list operations, then **cross-endpoint consistency** (pagination style, sort param shape, filter conventions).

## Pagination


| Rule                                                                                                                                                                | Severity hints                                                                                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Every** collection endpoint MUST support pagination—responses must not be **unbounded** full table dumps                                                          | **error** if a list route can return all rows with no limit; **warning** if limit exists only in code but not in contract/docs                      |
| **Offset style**: `page`/`per_page` or `offset`/`limit` (or equivalent names). Document behavior under concurrent inserts/deletes (skipped/duplicate rows possible) | **note** when offset is used on large or highly mutable datasets; **warning** if that trade-off is undocumented                                     |
| **Cursor style**: `cursor`, `after`, or `next_page_token`—value is an **opaque** token; clients must not parse it as an offset                                      | **warning** if cursor is a raw DB id exposed without versioning/stability story; **error** if named "cursor" but implemented as offset without docs |
| **Response metadata**: include pagination info—e.g. `total` (when feasible), `**next` link or next cursor**, `**has_more`** / `hasNextPage`, current `limit`        | **error** if clients cannot tell whether more pages exist; **warning** if totals promised but expensive/unimplemented                               |
| **Defaults and caps**: sensible **default** page size (e.g. **20**) and **maximum** cap (e.g. **100**); server enforces cap even if client sends higher             | **error** if no max cap (e.g. client can request 1,000,000); **warning** if default missing or extreme (0, unlimited)                               |
| Prefer **cursor** pagination for **large** or **real-time** datasets; offset is acceptable for small/stable lists if documented                                     | **note** (recommendation), not an error for small internal lists                                                                                    |


## Filtering


| Rule                                                                                                                                                            | Severity hints                                                                                                        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Filters belong in **query** parameters: e.g. `/users?status=active&role=admin`                                                                                  | **warning** if many filter dimensions are crammed into **path** segments that look like filters                       |
| Support **multiple values** where logical: repeated (`?status=active&status=pending`), bracket (`?status[]=...`), or comma-separated—**one** convention per API | **warning** if multi-value is needed but only single value is accepted; **note** to document chosen multi-value style |
| **Document** which query params are **filterable**; **do not** silently ignore unknown filter params—return **400** or strict validation                        | **error** if unknown filters are ignored; **warning** if filter params exist in examples but are not implemented      |
| Flag handlers that **accept** filter query keys but **omit** them from the query (silent no-op)                                                                 | **error** / **warning** (same as unknown filters—breaks client trust)                                                 |


## Sorting


| Rule                                                                                                                       | Severity hints                                                                                            |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **One** consistent sort param style API-wide, e.g. `?sort=created_at` or `?sort=-created_at` (`**-` prefix** = descending) | **warning** if some endpoints use `order=desc&sort=...` and others use `-field` without documented reason |
| **Multi-field**: e.g. `?sort=-created_at,name` (document delimiter and direction rules)                                    | **warning** if multi-sort is needed but only single field works                                           |
| **Document** which fields are **sortable**; define a **default** sort for **every** collection endpoint                    | **warning** if default order is undefined or unstable; **error** if `sort` param is accepted but ignored  |
| Flag **sort** params that are parsed but **not applied** to the backing query                                              | **error** / **warning**                                                                                   |


## Partial responses / field selection


| Rule                                                                                                           | Severity hints                                                                                                |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Optional: support sparse fieldsets, e.g. `?fields=id,name,email` (or `select`, `projection`—document the name) | **note** only—absence is not a defect                                                                         |
| If supported: **validate** field names; **reject** unknown fields (**400**) instead of silently ignoring       | **warning** if partial fields are accepted but unknowns are ignored; **error** if that skews security/billing |


## Anti-patterns (flag explicitly)


| Anti-pattern                                                   | Typical severity        |
| -------------------------------------------------------------- | ----------------------- |
| Collection endpoint with **no** pagination / no limit          | **error**               |
| **No** maximum page size                                       | **error**               |
| **Missing** pagination metadata (`has_more`, next, etc.)       | **error**               |
| **Inconsistent** pagination style across list endpoints        | **warning**             |
| Filter or sort params **accepted but silently ignored**        | **error** / **warning** |
| Undocumented **filterable** / **sortable** fields              | **warning**             |
| Cursor that is **not** opaque or **not** stable across changes | **warning**             |


## Severity guide

- **error**: Unbounded or unsafe lists, broken contract (ignored filters/sorts), missing caps, or missing metadata that blocks correct paging.
- **warning**: Inconsistent conventions, undocumented trade-offs, or brittle patterns before external freeze.
- **note**: Optional field selection, offset-vs-cursor guidance, or documented internal exceptions.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <METHOD /path, parameter name, file:line, or schema name>
- issue: <what violates which rule>
- suggestion: <concrete fix: add limit/cap, cursor + has_more, validate filters, document sortables, etc.>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Inventory** all collection/list operations (plan: `paths`; code: route tables, `GetMany`, index actions).
2. **Pagination pass**: params, defaults, max cap, response metadata, unbounded queries.
3. **Filtering pass**: query vs path, multi-value style, documented filterables, unknown param handling.
4. **Sorting pass**: param syntax, multi-sort, default order, sortables documented, sort applied in data layer.
5. **Field selection pass** (if present): validation of field names; otherwise **note** optional improvement.
6. **Consistency pass**: same pagination and sort conventions across endpoints; flag drift.

## What this skill does not cover

Authn/z, idempotency, caching headers, full URL path design, error payload shape, or non-collection routes—pair with **request-response-shape**, **rest-api-url-design**, and **http-methods-status** when those are in scope.