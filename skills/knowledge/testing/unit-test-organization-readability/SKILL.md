---
name: unit-test-organization-readability
description: >-
  Reviews unit test file organization, suite structure, naming, Arrange-Act-Assert  clarity, readability as documentation, setup/teardown choices, and file size.
  Heavier in review changes (concrete files/diffs); review plan flags conventions
  and risks in test strategy. Use when reviewing tests, test layout, describe/it
  structure, AAA style, beforeEach vs inline setup, splitting large test files,
  or PRs touching tests. Triggers: test organization, test readability, describe
  nesting, test naming, co-located tests, __tests__, *.spec.ts, *.test.ts, AAA,
  beforeEach, test file too long, review changes, review plan.
---

# Unit test organization & readability review

Apply when reviewing **test files**, **test-related diffs**, or **test strategy in a plan**.

## Operating modes

| Mode | Focus | Typical input |
|------|--------|----------------|
| **review changes** (primary) | Concrete paths, `describe`/`it` titles, structure in diff, line-level AAA and setup | Files, PR diff, pasted test blocks |
| **review plan** | Team conventions, risks of huge files, unclear grouping, missing naming rules | "How we'll test", folder layout decisions, standards docs |

If the mode is omitted: **strategy / conventions only** → **review plan**; **files or diffs** → **review changes**.

**Cross-skill scope**: This skill is about **structure and readability**. Pair with `unit-test-smells` (anti-patterns, flakiness, coupling) and `assertion-quality-review` (matcher choice, assertion depth)—do not re-audit assertion catalogs here.

---

## 1. File organization

**Check**

- **Location**: Co-located (`foo.ts` + `foo.test.ts` side by side) vs centralized (`__tests__/`, `test/`, `tests/`). Either can be valid; **consistency within the repo** matters.
- **Naming**: `*.test.*` vs `*.spec.*`—pick one primary pattern per codebase; avoid mixing in the same directory without a documented reason.
- **Mapping**: Prefer **one test file per source module** (or obvious submodule). Multiple tiny sources may share a test file only if documented and rare.

**Good**

```text
src/users/UserService.ts
src/users/UserService.test.ts
```

**Bad**

```text
src/users/UserService.ts
tests/integration-ish/mega-suite.test.ts   // covers UserService + 4 other modules
```

**review plan**: Call out if the plan leaves **naming or folder rules** undefined—predicts mixed patterns and orphaned tests.

**review changes**: Name the **source ↔ test** mapping; flag new tests in a file that no longer matches a single unit.

---

## 2. Suite nesting (`describe` / `context`)

**Check**

- Group by **unit under test**, then **method or behavior**, then **scenario** (happy path, validation error, edge case).
- **Depth**: Aim for **≤ 3 levels** of nested `describe` in the common case. Deeper nesting usually means missing extraction or muddled grouping.
- **Titles**: Each block should add **scoping**, not repeat the parent verbatim.

**Good**

```typescript
describe("UserService", () => {
  describe("findActiveByTeam", () => {
    it("returns only users with active membership in the team", () => { /* ... */ });
    it("returns an empty list when the team has no members", () => { /* ... */ });
  });
});
```

**Bad** (over-nested, redundant)

```typescript
describe("UserService", () => {
  describe("when using UserService", () => {
    describe("and calling findActiveByTeam", () => {
      describe("when things happen", () => {
        it("works", () => { /* ... */ });
      });
    });
  });
});
```

**review plan**: If the plan says "one big describe per file" or no grouping rule, note **hard-to-navigate** suites as a risk.

**review changes**: Point to **exact** `describe` lines; suggest flattening or regrouping by **behavior**.

---

## 3. Test naming (`it` / `test`)

**Check**

- Names should read as **specifications**: *given context, expected outcome*.
- Avoid vague verbs: "works", "handles correctly", "edge case", "does the thing".
- **Consistency**: Prefer one pattern repo-wide, e.g. `"should <outcome> when <condition>"` **or** imperative `"returns … when …"`—not a mix in the same module.

**Good**

- `it("returns an empty array when no items match the filter", ...)`
- `it("rejects with ValidationError when email is missing", ...)`

**Bad**

- `it("works", ...)`
- `it("handles edge case", ...)`
- `it("filter", ...)`  // noun-only, no outcome

**review plan**: Recommend documenting the **chosen pattern** in team guidelines.

**review changes**: Quote weak titles; suggest renames that state **observable behavior**.

---

## 4. Arrange–Act–Assert (AAA)

**Check**

- **Single act**: One primary invocation under test per test (the "act"). If you need two acts, you likely have two behaviors.
- **Visual separation**: Blank line between Arrange / Act / Assert, or brief `// Arrange` comments where it helps—especially in longer tests.
- **Assert clarity**: Assertions should follow naturally from the act without "mystery" state from distant lines.

**Good**

```typescript
it("marks the invoice as paid when payment succeeds", async () => {
  const invoice = createInvoice({ status: "open" });
  const payments = createPaymentsClient({ result: "success" });

  await payInvoice(invoice.id, payments);

  expect(await loadInvoice(invoice.id)).toMatchObject({ status: "paid" });
});
```

**Bad** (no separation, multiple acts)

```typescript
it("payment flow", async () => {
  const invoice = createInvoice({ status: "open" });
  await holdInvoice(invoice.id);
  await payInvoice(invoice.id, payments);
  expect(await loadInvoice(invoice.id)).toMatchObject({ status: "paid" });
});
```

**review plan**: Flag strategies that encourage **mega-tests** or "integration-style" unit tests without AAA discipline.

**review changes**: Mark where to **split** tests or insert separation; call out **extra acts** that deserve their own case.

---

## 5. Test readability (documentation value)

**Check**

- A new developer should understand **the behavior under test** from the test alone—within reason (domain types can exist).
- **No control-flow logic in tests**: avoid `if` / `for` / `switch` to branch expectations; use separate tests or **table-driven** tests with explicit rows.
- **Indirection**: Helpers are fine when they **name** a boring mechanic (`createUser()`). Avoid helpers that hide **the claim** of the test (`assertEverythingMatchesContract(x)`).

**Good** (small helper with clear intent)

```typescript
function buildCartWithSingleLine(itemId: string) {
  return { lines: [{ itemId, qty: 1 }] };
}
```

**Bad** (logic and vague helper)

```typescript
for (let i = 0; i < scenarios.length; i++) {
  if (scenarios[i].kind === "refund") {
    expect(process(scenarios[i])).toBe(true);
  } else {
    expect(process(scenarios[i])).toBe(false);
  }
}
```

**review plan**: Warn against **frameworks** that force deep inheritance or shared "mega-setup" for unit tests.

**review changes**: Flag branches/loops; suggest **parameterized** tests or **split cases**; rename or inline helpers that obscure the assertion story.

---

## 6. Setup and teardown

**Check**

- **`beforeEach` / `afterEach`**: Use for **truly shared**, **repeatable** setup (mocks reset, temp dirs, clock). Keep hooks **minimal**; prefer local arrange when only one test needs a value.
- **Shared setup smell**: Hook creates objects that only **some** tests mutate—risks **order dependence** and hidden coupling.
- **`beforeAll` / `afterAll`**: Fine for **expensive immutable** setup (starting a local server, building a schema). **Avoid `beforeAll` for mutable state** shared by tests unless the resource is **read-only** or **externally synchronized** and the pattern is standard for that stack.

**Good**

```typescript
beforeEach(() => {
  resetMocks();
  useFakeTimers();
});
afterEach(() => {
  runOnlyPendingTimers();
  useRealTimers();
});
```

**Bad**

```typescript
let user: User;
beforeAll(async () => {
  user = await createUser(); // mutated by multiple tests
});
```

**review plan**: Note missing **reset strategy** for mocks, env, or global singletons.

**review changes**: Point to hooks that should move **inline** or split into **context-specific** nested `describe` blocks.

---

## 7. Test file size and focus

**Check**

- **Soft thresholds** (adapt to team norms): flag files **> ~300–400 lines** or **> ~30–40 cases** as candidates to split—especially if multiple unrelated types or features appear.
- **Single focus**: One test file should target **one module/unit** (or one feature slice). If sections are unrelated, split by **type** or **behavior area**.
- **review changes**: Prefer suggesting **concrete split points** (e.g. "move `describe('refunds')` to `RefundService.test.ts`").

**Good**

- `OrderTotals.test.ts` only for pure pricing/totals logic.

**Bad**

- `everything.test.ts` with payment, notifications, and PDF rendering cases.

**review plan**: If the plan anticipates **one huge suite** per epic, recommend **per-module** files early.

---

## Output format

Use concise, scannable feedback:

1. **Summary** (2–4 bullets): strongest issues first.
2. **Findings** grouped by section above, each with:
   - **Severity**: blocking / should-fix / suggestion
   - **Location**: path + line or test title (review changes); convention gap (review plan)
   - **Fix**: concrete rewrite, split, or convention to adopt

**Mode emphasis**: In **review changes**, place **most** of the detail on **specific** files, titles, and structure. In **review plan**, emphasize **conventions and risks** that will produce messy suites later.

---

## Quick checklist

- [ ] File placement and naming match repo convention; one module ↔ one test file (exceptions justified).
- [ ] `describe` depth ≤ ~3; grouping by behavior/scenario is obvious.
- [ ] Test titles state **outcome + condition**; no vague names.
- [ ] AAA visible; **one primary act** per test.
- [ ] No branching loops disguising multiple scenarios; helpers clarify rather than hide.
- [ ] Hooks only for **common** setup; no shared **mutable** `beforeAll` without strong justification.
- [ ] Oversized files flagged with a **split** suggestion.
