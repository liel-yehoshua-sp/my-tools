# Workflow: Installation

> Use this workflow when setting up AI Elements in a new or existing project for the first time.

## Prerequisites Check

1. Verify Node.js 18+: `node --version`
2. Verify the project is Next.js: check for `next` in `package.json`
3. Verify Tailwind CSS is configured: check for `tailwind.config.*` or `@tailwind` directives

## Steps

### Step 1: Install shadcn/ui (if not present)

Check if `components.json` exists at the project root.

- **If missing**: Run `npx shadcn@latest init` and select CSS Variables mode
- **If present**: Verify `style` is set to use CSS variables (not class-based)

### Step 2: Install AI SDK

```bash
npm install ai @ai-sdk/react
```

Verify with: `grep "@ai-sdk/react" package.json`

### Step 3: Install AI Elements

**Option A — Install all components:**
```bash
npx ai-elements@latest
```

**Option B — Install specific components:**
```bash
npx ai-elements@latest add {{COMPONENT}}
```

**Option C — Via shadcn CLI:**
```bash
npx shadcn@latest add https://elements.ai-sdk.dev/api/registry/{{COMPONENT}}.json
```

### Step 4: Verify Installation

Run the search script to confirm components are in place:
```bash
bash scripts/search-component.sh {{PROJECT_ROOT}} {{COMPONENT}}
```

Check that files exist in `@/components/ai-elements/`.

### Step 5: Configure API Route

Create a basic chat API route:

```ts
// app/api/chat/route.ts
import { streamText, UIMessage, convertToModelMessages } from "ai";

export const maxDuration = 30;

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json();
  const result = streamText({
    model: "anthropic/claude-sonnet-4.5", // or your preferred model
    messages: await convertToModelMessages(messages),
  });
  return result.toUIMessageStreamResponse();
}
```

### Step 6: Set Up Environment

Add to `.env.local`:
```
AI_GATEWAY_API_KEY=your-key-here
# Or provider-specific keys:
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-ant-...
```

### Step 7: Health Check

Run the health check script to validate everything:
```bash
npx tsx scripts/health-check.ts {{PROJECT_ROOT}}
```

### Step 8: Verify With Minimal Chat

Create a minimal page to confirm the setup works end-to-end. See `references/best-practices.md` for the core integration pattern.

## Post-Installation

- Read `references/conventions.md` for file structure and naming
- Read `references/rules.md` for hard rules
- Read `references/best-practices.md` for integration patterns
