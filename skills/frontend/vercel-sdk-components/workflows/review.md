# Workflow: Review

> Use this workflow when reviewing code changes that involve AI Elements components.

## Steps

### Step 1: Identify Changed Files

List all files changed in the PR/commit/diff that import from `@/components/ai-elements/`.

```bash
bash scripts/list-usage.sh {{PROJECT_ROOT}}
```

Cross-reference with the changed files to find AI Elements usage in the diff.

### Step 2: For Each Changed File Using AI Elements

Let `{{FILE}}` = the changed file path.

#### 2a: Identify Components Used

Extract all imports from `@/components/ai-elements/*` in `{{FILE}}`.

For each imported component, let `{{COMPONENT}}` = the component name and read its detail file at `references/components/{{COMPONENT}}.md`.

#### 2b: Validate Against Rules

Check every rule in `references/rules.md`:

| Rule | Check |
|------|-------|
| R1 | Is `useChat` connected? |
| R2 | Is Streamdown CSS imported (if MessageResponse used)? |
| R3 | Is `"use client"` present? |
| R4 | Are AI Elements source files modified directly for bug fixes? |
| R5 | Does Conversation have a fixed-height container? |
| R6 | Is `message.parts` used (not `message.content`)? |
| R7 | Does the server route have required flags? |
| R8 | Are competing chat UI libraries mixed in? |
| R10 | Is CSS Variables mode used? |

#### 2c: Validate Against Best Practices

Check `references/best-practices.md`:

- [ ] Components are composed (not used monolithically)
- [ ] Status from useChat is used for loading states
- [ ] TypeScript types are correct (UIMessage, ToolUIPart)
- [ ] Dark mode is handled (especially for CodeBlock)
- [ ] Conversation has proper height constraint

#### 2d: Validate Against Conventions

Check `references/conventions.md`:

- [ ] Components in correct directory (`@/components/ai-elements/`)
- [ ] Imports follow the convention
- [ ] Naming follows PascalCase for components, camelCase for hooks
- [ ] API routes follow `app/api/*/route.ts` pattern
- [ ] No duplicated state (useChat is single source of truth)

#### 2e: Validate Scenarios

Read `references/components/{{COMPONENT}}.md` → Scenarios section:
- Is the component being used for a **Good Fit** scenario?
- Is it being used for a **Bad Fit** scenario? If so, flag it and suggest the alternative.

### Step 3: Check for Missing Components

Look at the rendered UI intent. Are there AI patterns that SHOULD use an AI Elements component but don't?

Common misses:
- Streaming text without MessageResponse → should use MessageResponse
- Tool calls rendered as raw JSON → should use Tool component
- Reasoning content shown as plain text → should use Reasoning component
- No auto-scroll in chat → should use Conversation wrapper
- No loading state → should use Shimmer

### Step 4: Report Findings

Categorize issues as:
- **🔴 Rule Violation**: Must fix before merge
- **🟡 Best Practice Gap**: Should fix, not blocking
- **🟢 Convention Gap**: Nice to fix, informational
- **💡 Suggestion**: Optional improvement
