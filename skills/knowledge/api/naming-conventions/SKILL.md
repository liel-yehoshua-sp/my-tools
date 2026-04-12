---

## name: naming-conventions

description: >-
  Reviews REST API naming: field casing, path/query conventions, abbreviations,
  booleans, collections, generic names, timestamp/ID consistency, and domain
  language (ubiquitous language, synonyms, acronym casing). Use when reviewing
  OpenAPI specs, JSON Schemas, design docs, example payloads, DTOs,
  serializers, route tables, or diffs for a JSON HTTP API. Triggers: API naming
  review, camelCase vs snake_case, field names, query params, kebab-case paths,
  REST code review agent, ubiquitous language, naming consistency.

# REST API naming conventions (review agent)

Apply when evaluating **names** on the API surface: **paths**, **query parameters**, **request/response fields**, and **schema titles**—from a **plan/spec** or **implementation/diff**.

## Operating modes


| Mode               | Typical input                                                     | `location` field                                                                                      |
| ------------------ | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Review plan**    | OpenAPI `paths` / `components/schemas`, design docs, example JSON | `METHOD /path`, path template, schema name, property path, or doc section                             |
| **Review changes** | Diffs, DTOs, serializers, route config, validation attributes     | `file:line` when visible; else `METHOD /path`, `?queryParam`, or JSON pointer–style `schema.property` |


If both exist, prioritize **changed** operations and schemas, then scan **cross-endpoint** naming drift.

## Field casing (JSON bodies and metadata)


| Rule                                                                                                                                                                                                                                                               | Severity hints                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| Pick **one** convention API-wide: **camelCase** (typical JS/TS clients) **or** **snake_case** (typical Ruby/Python). Apply to **all** JSON object keys the API owns (including nested objects and error bodies unless a standard error format dictates otherwise). | **error** when the same API mixes conventions across operations or schemas                             |
| **Query parameter** names must match the chosen body convention (`userId` vs `user_id`).                                                                                                                                                                           | **error** for mismatch with documented body casing                                                     |
| **Path segments** are **not** JSON keys: use **kebab-case** for multi-word resources (`/order-items`). Never `camelCase` or `snake_case` in path segments.                                                                                                         | **error** for `/orderItems` or `/order_items` when segments are meant as human-readable resource words |
| **HTTP headers** follow **Hyphenated-Pascal-Case** per HTTP; do not use this skill to demand camel/snake in headers—only flag if custom `X-` headers invent inconsistent spelling of the same concept.                                                             | **warning** for duplicate concepts with different spellings in custom headers                          |


## Naming clarity


| Rule                                                                                                                                                                                                                                                | Severity hints                                                               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Prefer **full words**: `createdAt` not `cAt`; `description` not `desc`. Allow **universal** short forms when industry-standard: `id`, `url`, `href`, `etag` (document domain-specific allowed abbreviations if any).                                | **warning** for unexplained abbreviations; **note** if glossary defines them |
| **Booleans** must read as **predicates**: `isActive`, `hasChildren`, `canEdit`—not bare nouns/adjectives like `active`, `children`, `edit` when the value is true/false.                                                                            | **warning** (or **error** if names collide with related resource arrays)     |
| **Collections** use **plural** keys: `items`, `tags`, `roles`—not singular `item`/`tag`/`role` for array-valued fields.                                                                                                                             | **warning**                                                                  |
| Avoid **generic** keys that carry no domain meaning: `data`, `info`, `result`, `object`, `thing`, `payload` (unless part of a **documented** envelope pattern—then pair with `request-response-shape` and still require inner keys to be specific). | **warning** for vague inner fields; **note** for documented envelope roots   |


## Consistency (same concept, same name)


| Rule                                                                                                                                                                                      | Severity hints                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| One identifier per concept: do not use `userId` in one place and `user_id` in another; avoid `createdAt` vs `created_date` for the same event.                                            | **error** for direct synonyms with different casing or wording on the same resource lifecycle |
| **Timestamps** follow one pattern: `createdAt`/`updatedAt` **or** `created_at`/`updated_at`—not mixed.                                                                                    | **error** when both styles appear API-wide                                                    |
| **IDs** follow one pattern per concept: `userId`/`orderId` **or** `user_id`/`order_id`.                                                                                                   | **error** when the same entity ID switches style between endpoints                            |
| **Associations** mirror naming: if a user reference is `ownerId`, avoid `ownerUserId` elsewhere for the same foreign key unless the domain truly distinguishes them—call out duplication. | **warning**                                                                                   |


## Domain language (DDD ubiquitous language)


| Rule                                                                                                                                                                                   | Severity hints                                                               |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Use **business terms** from the domain; names should match product/docs vocabulary.                                                                                                    | **note** / **warning** when code invents alternate terms with no distinction |
| Do not **synonym-hop** for the same aggregate: e.g. `order` in one area and `purchase`/`transaction` elsewhere for the same thing—pick one term or model separate concepts explicitly. | **warning** (or **error** if it breaks client mental model or search)        |
| **Acronyms** inside keys: **camelCase** → `htmlContent`, `apiVersion`; **snake_case** → `html_content`, `api_version`. Avoid `HTMLContent`, `APIVersion`, or `HTML_Content`.           | **warning**                                                                  |
| **Known brand/acronym exceptions** (e.g. `sku`, `iban`) may stay lowercase within the chosen convention; flag only if inconsistent with the rest of the API or domain docs.            | **note**                                                                     |


## Anti-patterns (flag explicitly)


| Anti-pattern                                                    | Typical severity        |
| --------------------------------------------------------------- | ----------------------- |
| Mixed **camelCase** and **snake_case** on the same API surface  | **error**               |
| **Paths** using camelCase or snake_case segments                | **error**               |
| **Query** casing differs from body casing                       | **error**               |
| Unexplained **abbreviations**                                   | **warning**             |
| **Generic** field names (`data` inner fields, `info`, `result`) | **warning**             |
| Same concept, **different names** across endpoints              | **error** / **warning** |
| **Boolean** fields that are not predicates                      | **warning**             |
| **Singular** names for array fields                             | **warning**             |
| **Acronyms** breaking the casing convention                     | **warning**             |


## Severity guide

- **error**: Contract drift clients will encode wrong (mixed casing, path segment style, mismatched query/body), or contradictory naming for the same concept.
- **warning**: Confusing, brittle, or unclear; fix before external freeze or broad client adoption.
- **note**: Documented exception, legacy subdomain with explicit carve-out, or optional polish.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <field path, query name, path segment, METHOD /path, schema name, or file:line>
- issue: <what violates which rule>
- suggestion: <concrete rename, convention choice, or doc alignment>
```

Sort findings: **error** → **warning** → **note**. If clean, give a one-line summary of conventions assumed (camel vs snake, sample path) and what was checked.

## Review procedure

1. **Detect convention**: Infer dominant casing from schemas/examples; if unclear, **note** the assumption.
2. **Path pass**: multi-word segments kebab-case? No camel/snake in segments?
3. **Query pass**: aligns with body convention?
4. **Schema pass**: abbreviations, booleans, plural collections, generic keys, acronym casing.
5. **Concept map pass**: build a mental map of entities (user, order, …)—flag synonym or style splits.
6. **Timestamp/ID pass**: uniform suffixes and separators.

## What this skill does not cover

Envelope shape, pagination object layout, HTTP verbs/status codes, auth, or full OpenAPI style—pair with **request-response-shape**, **url-design**, and HTTP skills when those are in scope.