---
name: assertion-quality-review
description: >-
  Reviews test assertions for specificity, focus, clarity, async safety, and
  correct matchers (equality vs truthy, asymmetric matchers, snapshots, negatives,
  floats, types, assertion counts). Use when reviewing test changes, PRs, or
  test plans; triggers include Jest, Vitest, expect, assertions, matchers,
  snapshots, flaky tests, and "review changes" or "review plan" for tests.
---

# Assertion quality & correctness review

Apply when the user supplies **tests, test utilities, or a test strategy** plus a **mode**:

- **review plan**: Flag **patterns** that predict weak or misleading tests: blanket truthy checks, mega-tests, snapshot-heavy UI coverage without intent, async suites without assertion guards, float equality by default.
- **review changes**: Point to **concrete** `expect` / `assert` calls and test bodies: replace vague matchers, split unrelated concepts, add messages where failures are opaque, fix async/promise mistakes, tighten snapshots.

If the mode is omitted, **infer** it: design docs / test strategy → **review plan**; diffs / PRs / files → **review changes**.

Map terminology to the stack (Jest, Vitest, Testing Library, Cypress, pytest, Ruby RSpec, JUnit/Hamcrest, Go `testify`, .NET xUnit/NUnit/FluentAssertions, etc.). Examples below use **Jest-style** `expect`; translate idioms.

---

## 1. Assertion specificity

**Prefer the narrowest matcher that expresses the intent.**

- **Object/value shape**: Prefer deep equality on the relevant slice (`toEqual`, `toStrictEqual`, object partials) over `toBeTruthy()` / `toBeDefined()` when the test cares about **content**.
- **Collections**: Prefer `toHaveLength(n)`, `toContain(item)`, set/array equality, or order-sensitive checks only when order matters—over `expect(arr.length).toBe(3)` or `toBe(true)` on a length predicate.
- **Strings**: Prefer `toMatch`, `toContain`, or regex over truthy checks on `.includes()`.
- **Booleans from predicates**: If the assertion is `expect(isValid).toBe(true)`, consider asserting **why** (error list, parsed result, status code) unless the boolean is the actual API.

**review plan**: Ban "happy path truthy" as the default pattern for structured outputs.

**review changes**: Flag `toBeTruthy` / `toBeFalsy` / bare `if (result)` in tests when a field or error message should be asserted.

---

## 2. Single assertion per concept

**One logical behavior per test**; multiple `expect` calls are fine when they **characterize the same outcome** (e.g. status + body, or several fields of one saved entity).

- **Avoid**: unrelated expectations in one test (e.g. user creation + email sender + metrics in a single case)—splits make failures **diagnostic**.
- **Prefer**: arrange/act once per behavior; use **nested describe** or test names that state the behavior.

**review plan**: Require naming conventions or templates that encode **one scenario per test** for complex flows.

**review changes**: Suggest extracting tests when expectations cover **independent** behaviors or failure modes.

---

## 3. Error messages (failure clarity)

Add a **custom message** when the default output would not show **what went wrong**:

- Boolean expectations, generic `toBe(true)`, or multi-branch logic where the value alone is ambiguous.
- **Loops / table-driven** tests: include **iteration index** and input row in the message.
- **Floating tolerances** or **timeouts**: state the expected bound and actual context.

In Jest, use the second argument to `expect` or message options where supported; in pytest, `assert expr, "..."`; in other frameworks, use the idiomatic message parameter.

**review changes**: If a failure would read "expected false to be true" with no **domain** context, request a message or richer matcher.

---

## 4. Asymmetric / partial matchers

Use **partial** expectations when only a subset of fields matters:

- **`expect.objectContaining`**: stable subset of keys; pair with **specific** matchers inside when needed (`expect.any(Number)`, nested `objectContaining`).
- **`expect.arrayContaining`** / order-insensitive patterns: when order is not part of the contract; otherwise assert **exact** order.
- **`expect.any(Type)` / `expect.anything()`**: for dynamic IDs, timestamps, or protocol envelopes—**narrow** the type (e.g. `String` + format) when the contract requires it.

**Anti-pattern**: `objectContaining` with **only** `expect.any(...)` for every field—often too weak; assert **at least one** concrete business field.

**review plan**: Document where **partial** matching is required (evolving DTOs) vs where **exact** snapshots or full equality are required (security-sensitive lists, money).

---

## 5. Snapshot assertions

**Good fits**: stable serialized output (compiler output, AST dumps, **small** CLI stdout), or intentional **golden** files for grammar/serialization when reviewed deliberately.

**Poor fits**: using snapshots **instead of** asserting behavior; huge React trees that churn on every style tweak; encoding **incidental** structure.

**Size & hygiene**:

- Prefer **small** snapshots; if the snapshot is hundreds of lines, assert **focused** subtrees or strip volatile fields.
- **Inline** snapshots for **short** literals in the test file; **file** snapshots for larger output—keep colocated and reviewed in PRs.
- Ensure snapshots are **deterministic** (sort keys, freeze timezones, mock randomness).

**review changes**: Flag new or bloated snapshots; ask what **regression** they catch. Prefer explicit `expect` on critical text/structure when churn is high.

---

## 6. Negative assertions

Verify that something **does not** happen when that is part of the contract:

- Examples: `not.toHaveBeenCalled()`, `not.toContain()`, `rejects` / `throws` with **specific** messages or types where relevant.

**Quality bar**: The test must **fail** if the forbidden behavior appears—avoid negatives that still pass when the code **does nothing** (e.g. asserting a mock was not called when it was never wired).

Pair negatives with **positive** evidence when needed: e.g. assert the primary path ran, **then** assert the side effect did not occur.

**review plan**: For error-handling stories, require **both** success-path and failure-path tests, not only "does not throw".

---

## 7. Async assertions

**Never** leave floating promises in tests; **await** async expectations end-to-end.

- **Promises**: `await expect(promise).rejects.toThrow(...)` / `.resolves...` (Jest) or framework equivalent; avoid `expect(promise).rejects` without awaiting if the framework requires it.
- **async mistakes**: `return promise` vs `await` in `try/catch`; use the framework-recommended pattern so failures surface.
- **Timers**: use fake timers **and** async flushing helpers (`waitFor`, `advanceTimers`) per framework docs.

**review changes**: Flag `promise` expectations without `await`/`return`; flag `try/catch` that swallows errors; flag `setTimeout` without synchronization.

---

## 8. Type-aware assertions

When values cross **dynamic** boundaries (JSON, `unknown`, generics, reflection), assert **types** that encode contracts:

- `toBeInstanceOf` / `assert isinstance` / type guards in TS tests.
- For **optional** fields, assert both presence **and** shape when the test intends to lock the contract.

Avoid redundant type checks on every line; apply where **incorrect typing would silently pass** (e.g. `as Foo` in production code).

---

## 9. Assertion count guards

In **async** or callback-heavy tests, use **`expect.assertions(n)`** (exact) or **`expect.hasAssertions()`** (at least one) when:

- Multiple code paths could skip assertions;
- Catch blocks might swallow failures;
- Loops issue conditional expects.

**review plan**: For event-driven and promise-chain suites, standardize on **hasAssertions** by default in async tests.

**review changes**: If a test has `await` + branching and no guard, suggest `hasAssertions` or narrow structure so every path asserts.

---

## 10. Floating-point comparisons

Never use **exact** equality for most floats; use **tolerance** APIs:

- Jest: `toBeCloseTo(expected, precisionDigits)`.
- Other stacks: `assertAlmostEqual`, `Within`, etc.

Also apply to **time durations** and **ratios** when derived from floats.

**review changes**: Flag `toBe` / `===` on computed doubles; confirm tolerance matches domain (financial code may need decimal types instead of float).

---

## Output format (review changes)

Group findings by file/test name. For each issue:

1. **What**: vague matcher / missing guard / risky snapshot / async smell.
2. **Why**: what regression could slip through.
3. **Change**: preferred matcher or structural fix (split test, add message, `toBeCloseTo`, `hasAssertions`).

Use severity that matches team norms (blocker vs suggestion). **Do not** nitpick stylistic matcher aliases if behavior and diagnostics are already strong.

---

## Quick checklist

- [ ] Matchers are as **specific** as the spec allows.
- [ ] Each test targets **one** behavior; related expects support one outcome.
- [ ] Custom **messages** where failures would be cryptic.
- [ ] Partial matchers **pin** meaningful fields, not only `any()`.
- [ ] Snapshots are **small**, stable, and justified.
- [ ] Negative tests would **fail** if the unwanted behavior appeared.
- [ ] Async: no **floating** promises; `rejects`/`resolves` properly awaited.
- [ ] Types asserted at **trust boundaries** where needed.
- [ ] `expect.assertions` / `hasAssertions` in risky async tests.
- [ ] Floats use **tolerance** (or decimals), not `toBe`.
