# Workflow: Refactor a Component

> Use this workflow when upgrading, refactoring, or migrating AI Elements usage.

## Steps

### Step 1: Audit Current Usage

```bash
bash scripts/list-usage.sh {{PROJECT_ROOT}}
```

Identify all files using AI Elements and which components they import.

### Step 2: Determine Refactor Type

| Type | Description | Action |
|------|-------------|--------|
| **Version Upgrade** | AI Elements or AI SDK updated | Step 3 |
| **Component Swap** | Replace one component with a better fit | Step 4 |
| **Pattern Refactor** | Fix rule/convention violations | Step 5 |
| **Feature Addition** | Add new AI Elements components to existing UI | Use `workflows/create-component.md` |

### Step 3: Version Upgrade

1. Run health check: `npx tsx scripts/health-check.ts {{PROJECT_ROOT}}`
2. Reinstall components to get latest versions:
   ```bash
   npx ai-elements@latest
   ```
3. Check for breaking changes:
   - AI SDK v4 → v5: `message.content` → `message.parts`
   - AI SDK v5 → v6: Check migration guide at https://ai-sdk.dev
   - Look for deprecated imports or changed component APIs
4. Run the Review workflow (`workflows/review.md`) on all AI Elements files
5. Run tests

### Step 4: Component Swap

1. Identify the current component: `{{OLD_COMPONENT}}`
2. Identify the replacement: `{{NEW_COMPONENT}}`
3. Read both detail files:
   - `references/components/{{OLD_COMPONENT}}.md`
   - `references/components/{{NEW_COMPONENT}}.md`
4. Compare scenarios to confirm the swap is appropriate
5. Install the new component: `npx ai-elements@latest add {{NEW_COMPONENT}}`
6. Update imports in affected files
7. Update the composition pattern (sub-components differ between components)
8. Update server route if required (Rule R7)
9. Run the new component's testing checklist

Common swaps:
- Reasoning ↔ ChainOfThought (continuous stream vs discrete steps)
- Sources ↔ InlineCitation (list vs inline)
- Tool ↔ Confirmation (display vs approval)

### Step 5: Pattern Refactor

1. Run the Review workflow to identify all violations
2. For each violation, apply the fix:

| Violation | Fix |
|-----------|-----|
| Missing `"use client"` | Add directive |
| Using `message.content` | Switch to `message.parts` |
| Missing Streamdown CSS | Add import |
| No fixed height on Conversation | Wrap in fixed-height container |
| Monolithic usage | Decompose into sub-components |
| Missing server flags | Add `sendReasoning`/`sendSources`/`requireApproval` |
| Direct source modification | Extract to wrapper, revert source |

3. Validate each fix against `references/rules.md` and `references/best-practices.md`
4. Run tests

### Step 6: Post-Refactor Validation

1. Run health check: `npx tsx scripts/health-check.ts {{PROJECT_ROOT}}`
2. Run the Review workflow on changed files
3. Verify streaming works end-to-end
4. Check dark mode rendering
5. Test on mobile viewport
