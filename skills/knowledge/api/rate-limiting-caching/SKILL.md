---
name: rate-limiting-caching
description: >-
  Reviews REST APIs for rate limiting (headers, 429, Retry-After), HTTP caching
  (Cache-Control, ETag, conditional GETs), cache invalidation, Vary, and
  throttling design (token bucket, sliding window, tiers). Use when reviewing
  OpenAPI specs, gateway config, middleware, controllers, or diffs for public or
  authenticated HTTP APIs. Triggers: rate limit, throttling, 429, X-RateLimit,
  RateLimit header, cache, ETag, If-None-Match, 304, Cache-Control, CDN,
  API review agent, REST performance.
---

# Rate limiting and caching (REST API review)

Apply when evaluating **how clients are throttled**, **what can be cached**, and **how freshness is preserved**—from **plans/specs** or **implementation**.

## Operating modes


| Mode               | Typical input                                                                 | `location` field |
| ------------------ | ----------------------------------------------------------------------------- | ---------------- |
| **Review plan**    | OpenAPI `paths`/`responses`/`headers`, design docs, SLA/tier tables, CDN notes | `METHOD /path`, header name, `components` name, or doc section |
| **Review changes** | Diffs: middleware, filters, handlers, reverse-proxy/gateway rules, cache stores | `file:line` when visible; else `METHOD /path`, middleware, or config key |


If both exist, prioritize **changed** routes and **cross-cutting** behavior (global limiter, default `Cache-Control`, shared cache layers).

## Rate limiting


| Rule | Severity hints |
| ---- | -------------- |
| **Public** and **authenticated** APIs should enforce **rate limits** at the edge or application (defense against abuse and accidental overload) | **error** for public-facing routes with **no** documented or implemented limiting; **warning** for internal-only if scale story is missing |
| Return **standard** quota headers on rate-limited responses: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` (or equivalents clearly documented) | **warning** when limits exist but responses omit quota headers clients need for backoff |
| **Alternatively** use the **IETF draft** `RateLimit` header family: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`—**one** consistent convention per API surface | **note** when mixing `X-RateLimit-*` and `RateLimit-*` without migration notes |
| On exceed: respond **`429 Too Many Requests`** and include **`Retry-After`** (seconds or HTTP-date) when policy allows clients to retry | **error** for `429` **without** `Retry-After` when a retry window is knowable; **warning** if `429` body gives no timing hint either |
| **Document** limits **per endpoint** or **per tier** (anonymous vs authenticated vs premium)—include burst vs sustained where relevant | **warning** when tiers exist but limits are unspecified; **note** for single global limit if justified |
| Flag **public** endpoints with **no** rate limiting | **error** (default); downgrade only if explicitly out-of-scope (e.g. fully private mesh) |


## Caching


| Rule | Severity hints |
| ---- | -------------- |
| **`GET`** responses for **stable** or **rarely changing** data should send explicit **`Cache-Control`** (`max-age`, `public` vs `private`, `s-maxage` when shared caches apply) | **warning** when stable reads default to heuristic caching or no policy; **note** when `no-cache` is intentional for revalidation |
| Prefer **`ETag`** for conditional requests: honor **`If-None-Match`** and return **`304 Not Modified`** when representation is unchanged | **warning** on frequently polled or large payloads **without** strong validators; **error** when spec promises ETag but code never sets it |
| Use **`Last-Modified`** / **`If-Modified-Since`** as **complement** or alternative where timestamps are authoritative and cheap | **note** when only one validator type is used but both could reduce bandwidth |
| **Sensitive** or **user-specific** data: `Cache-Control: private`, and often **`no-store`** (or stricter) for tokens, account details, medical/financial payloads | **error** for personalized/sensitive **`GET`** marked **`public`** or long **`max-age`** without `private`/`no-store` |
| **Do not** treat **`POST`/`PUT`/`PATCH`/`DELETE`** responses as cacheable for shared caches—avoid `public` caching on mutations; default **`no-store`** or non-cacheable unless a rare safe pattern is documented (e.g. specific idempotent reads) | **error** / **warning** for `Cache-Control: public` or long TTL on typical mutation responses |
| Flag **`GET`** that returns **volatile** data (balances, queues, live counters) paired with **aggressive** caching (`public` + long `max-age` without revalidation) | **error** when stale data is unsafe; **warning** when stale is tolerable but undocumented |


## Cache invalidation and variance


| Rule | Severity hints |
| ---- | -------------- |
| **Mutations** (`POST`/`PUT`/`PATCH`/`DELETE`) should **invalidate** or **version** representations that **`GET`** may serve (app cache, CDN, reverse proxy) so clients do not see indefinite stale state | **warning** when writes never bump ETag/versions and no purge/invalidate path exists for cached `GET`s |
| **Document cache TTLs** (or max staleness) for **consumers**—especially for B2B and mobile offline behavior | **warning** when CDN/browser caching is implied but TTL/staleness is unspecified |
| Use **`Vary`** when the response **depends** on request headers such as **`Accept`**, **`Accept-Encoding`**, **`Authorization`**, **`Accept-Language`**—omit only when representation truly does not vary on those axes | **warning** when content negotiation or auth shape changes body but `Vary` is missing (shared cache poisoning / wrong payload) |


## Throttling patterns


| Rule | Severity hints |
| ---- | -------------- |
| Prefer **token bucket** or **sliding window** (or well-documented fixed window with burst allowance)—flag **naive per-second** counters that reset sharply and encourage thundering herds | **warning** for brittle windowing; **note** when algorithm is unspecified but limits are numeric only |
| **Differentiate** limits by **auth tier**: anonymous **<** authenticated **<** premium (or equivalent)—align with product and abuse model | **warning** when all callers share one bucket despite different cost/risk |
| Consider **per-endpoint** limits for **expensive** operations (search, exports, reports, bulk) even if global limits exist | **warning** when heavy endpoints share the same budget as cheap reads |


## Anti-patterns (flag explicitly)


| Anti-pattern | Typical severity |
| ------------ | ---------------- |
| **No** rate limiting on **public** APIs | **error** |
| **`429`** returned **without** `Retry-After` (and no other retry timing contract) | **error** / **warning** |
| Rate limits enforced but **no** quota headers in responses | **warning** |
| **`Cache-Control` missing** on **stable** `GET` endpoints where caching is expected | **warning** |
| Caching **authenticated** / **personalized** responses as **`public`** | **error** |
| **No** **`ETag`** (or equivalent) for **frequently polled** or **large** resources | **warning** |
| **`GET`** for **volatile** state with **long** **`max-age`** and no revalidation | **error** / **warning** |
| **`Vary`** omitted when response depends on **`Accept`** / **`Authorization`** | **warning** |
| Mutation succeeds but **cached `GET`** can stay **stale** indefinitely | **warning** |


## Severity guide

- **error**: Abuse exposure, incorrect caching of sensitive/personalized data, unsafe staleness, or broken client contract (`429` without guidance, missing limits on public routes).
- **warning**: Missing headers, undocumented limits/TTLs, weak invalidation, inconsistent quota header families, or expensive endpoints under-protected.
- **note**: Acceptable trade-offs, migration between header conventions, or context-dependent choices (internal vs external).

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <METHOD /path, file:line, header name, component, or config key>
- issue: <what violates which rule>
- suggestion: <concrete fix: headers, limiter algorithm, TTL, ETag, Vary, invalidation, docs>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Inventory**: documented limits/TTLs (plan) and code/config: gateway, ASP.NET middleware, `Response.Headers`, action filters, output caching, CDN rules.
2. **Rate limit pass**: per-route vs global; header presence; `429` + `Retry-After`; tier table vs implementation.
3. **Cache policy pass**: `Cache-Control` on `GET`; `public`/`private`/`no-store` vs sensitivity; accidental caching on mutations.
4. **Validation pass**: `ETag` / `Last-Modified`; `If-None-Match` / `If-Modified-Since` → `304` behavior for hot reads.
5. **Invalidation pass**: writes bump versions or purge keys; surrogate keys / tag purges at CDN if used.
6. **Variance pass**: `Vary` and content negotiation; auth-shaped bodies.
7. **Algorithm pass**: token bucket/sliding window vs naive counters; per-endpoint cost limits.

When the input is **incomplete**, state assumptions and list **what evidence** would upgrade a **warning** to **error** or clear it.
