---
name: auth-security
description: >-
  Reviews REST APIs for authentication, authorization, token handling, CORS,
  input validation, injection risks, sensitive data exposure, and security
  headers. Use when reviewing OpenAPI specs, security ADRs, auth middleware,
  controllers/handlers, or diffs for JSON HTTP APIs. Triggers: API security review, JWT, OAuth2, Bearer token, API key, IDOR, CORS, SQL injection,
  secrets in logs, HSTS, auth code review agent.
---

# Auth and security (REST API review)

Apply when evaluating **who can call what**, **how credentials move**, **what crosses the wire**, and **what gets logged**—from **plans/specs** or **implementation**.

## Operating modes


| Mode               | Typical input                                                                 | `location` field |
| ------------------ | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Review plan**    | OpenAPI `securitySchemes`, `security`, paths, examples, CORS notes in docs    | `METHOD /path`, `components` name, or doc section                      |
| **Review changes** | Diffs: auth filters, handlers, DB access, config (`CORS`, `Jwt*`, env usage) | `file:line` when visible; else `METHOD /path` or middleware/config key |


If both exist, prioritize **changed** auth paths and data access, then **cross-cutting** consistency (global CORS, default security headers, shared validators).

## Authentication


| Rule                                                                                                                                 | Severity hints                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Prefer **standard** mechanisms: **Bearer** tokens (JWT with documented validation, or opaque tokens via OAuth2-style flows), **API keys in headers** (e.g. `X-Api-Key`, `Authorization: ApiKey …`) | **error** for custom header schemes that contradict documented `securitySchemes` without justification |
| **Never** pass **credentials in URLs** (query/path)—they appear in **logs**, referrers, and browser history                                                                 | **error** for `?token=`, `?api_key=`, basic auth in URL, or password in path                                      |
| **JWT**: reasonable **`exp`**, and documented **`aud`** / **`iss`** (or equivalent resource-server checks); flag **none** / **alg=none** / missing signature verification in code examples           | **error** for obviously broken validation; **warning** when claims requirements are unspecified in spec |
| Support **refresh** or **rotation**—avoid designs that force full re-login for every short-lived token unless documented (e.g. public read-only API)                                                | **warning** when access tokens are very short-lived and no refresh/session renewal is defined for interactive clients |


## Authorization


| Rule                                                                                                                                 | Severity hints                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Every** state-changing and sensitive **read** operation must enforce **authorization**, not only authentication (identity ≠ permission)                                     | **error** for `POST`/`PUT`/`PATCH`/`DELETE` with no `security` entry or no code-level check when implied |
| **IDOR / ownership**: callers must not read or mutate another subject’s resources by **guessing IDs**—enforce tenant/user scope on every lookup | **error** when handlers use raw IDs from the client without a server-side ownership or policy check   |
| Use **roles**, **scopes**, or **claims** with **least privilege**; document required scopes per operation where OAuth2-style scopes apply                                       | **warning** when roles/scopes exist in the model but are not reflected per-operation in spec or code  |
| Flag responses that **vary by role** (different fields or presence) **without** documenting that behavior (clients and auditors cannot rely on the contract)                  | **warning** (undocumented role-shaped responses); **note** if documented as intentional |


## CORS


| Rule | Severity hints                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Do **not** use `Access-Control-Allow-Origin: *` in **production** for **credentialed** or **cookie/session**-based APIs                                  | **error** when spec or config shows `*` with `Allow-Credentials: true` or cookie auth |
| **Whitelist** explicit origins (environment-specific); avoid overly broad patterns | **warning** for `*` on authenticated APIs; **warning** for regex/wildcard origins that are too loose         |
| Do **not** **reflect** the request `Origin` header **blindly** into `Access-Control-Allow-Origin` without an allow-list (dynamic reflection is easy to misconfigure) | **error** when code/config echoes arbitrary origins |


## Input validation and injection


| Rule                                                                                                                                 | Severity hints                                                                                          |
| ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Validate and bound **all** inputs: **path**, **query**, **body**, and **security-relevant headers** (e.g. `Content-Type`, `Accept`, auth headers)   | **warning** when validation is unspecified or partial; **error** when types/constraints are absent for risky fields |
| Use **parameterized** queries / ORM bindings—flag **string concatenation** or format-string SQL/command construction                                 | **error** for obvious SQL/command injection patterns |
| **Reject** unexpected **`Content-Type`** for bodies that expect JSON or a specific binary type; document allowed types per operation               | **warning** when `consumes` is missing or permissive for mutation endpoints                           |
| Enforce **maximum request body size** and, where relevant, **field size** limits (uploads, text blobs) at gateway or framework level | **warning** when unlimited body size is implied for large-input endpoints                               |


## Sensitive data


| Rule | Severity hints                                                                 |
| ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Never** return **passwords**, **refresh tokens**, **API secrets**, or **raw session tokens** in normal **GET** or mutation responses    | **error** if examples or code return these; **warning** if response schemas could include them      |
| **Mask** or **omit** highly sensitive fields (**SSN**, **full PAN**, **CVV**, **bank account**) in APIs not strictly required to show them | **error** / **warning** based on domain; prefer tokenized or last-four patterns when exposure needed |
| Use **HTTPS** only in public examples and base URLs—flag **`http://`** for production surfaces | **error** for documented prod `http`; **warning** for mixed-content examples                      |
| Do **not** log **secrets**, **full tokens**, **passwords**, or **full PII** bodies—prefer redaction and structured log fields             | **error** when logging middleware prints headers/bodies with credentials |


## Security headers


| Rule | Severity hints                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| Send **`Strict-Transport-Security`** on HTTPS responses where the API is browser-facing or mixed clients exist (document max-age policy)                    | **warning** when browser clients are likely and HSTS is absent |
| Set **`X-Content-Type-Options: nosniff`** and a sensible **`X-Frame-Options`** or **`Content-Security-Policy`** frame policy for APIs served to browsers    | **note** / **warning** for browser-facing UIs; lower priority for pure machine JSON |
| Return **`Cache-Control: no-store`** (and friends) for responses containing **auth decisions**, **tokens**, or **sensitive personal data**                  | **warning** when sensitive GETs are cacheable by default                           |


## Anti-patterns (flag explicitly)


| Anti-pattern                                                | Typical severity |
| ----------------------------------------------------------- | ---------------- |
| API keys or tokens in **query strings**                     | **error**        |
| **Wildcard CORS** on **authenticated** endpoints          | **error**        |
| **Missing authz** on **state-changing** endpoints         | **error**        |
| Returning **passwords** or **tokens** in **GET** responses  | **error**        |
| **No validation** before **DB** or external side effects    | **error**        |
| **Hardcoded secrets** in source or committed config         | **error**        |


## Severity guide

- **error**: Exploitable misconfiguration, credential leakage, missing authorization on mutations, or clear injection/log exposure.
- **warning**: Weaker guarantees, undocumented but risky gaps, or missing hardening that is standard for the deployment context.
- **note**: Optional improvements, browser-only headers for non-browser clients, or acceptable patterns that should still be called out for awareness.

## Finding format (required)

For **every** issue:

```text
- severity: error | warning | note
- location: <METHOD /path, file:line, component name, or config key>
- issue: <what violates which rule>
- suggestion: <concrete fix: scheme change, middleware, validation, CORS policy, header, logging>
```

Order findings: **error** → **warning** → **note**. If clean, give a one-line summary of what was checked.

## Review procedure

1. **Inventory**: documented `security` / `securitySchemes` (plan) and code entry points: auth middleware, global filters, per-route attributes, CORS config.
2. **Authentication pass**: Bearer/API key placement, URL credentials, JWT claims and lifetime, refresh story vs. product needs.
3. **Authorization pass**: every mutating route and sensitive read—policy, scopes, ownership checks; IDOR patterns (`FindById` without tenant).
4. **CORS pass**: allowed origins, credentials, reflection—aligned with cookie vs. bearer usage.
5. **Input pass**: validation coverage, `Content-Type`, size limits; scan for string-built SQL/commands.
6. **Data exposure pass**: response examples/schemas, logging, cache headers; HTTP vs HTTPS in docs and code.
7. **Headers pass** (browser-relevant): HSTS, `nosniff`, framing, `no-store` for sensitive responses.

When the input is **incomplete**, state assumptions and list **what evidence** would upgrade a **warning** to **error** or clear it.
