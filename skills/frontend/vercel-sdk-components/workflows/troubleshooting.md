# Workflow: Troubleshooting

> Use this workflow when debugging issues with AI Elements components.

## Steps

### Step 1: Run Health Check

```bash
npx tsx scripts/health-check.ts {{PROJECT_ROOT}}
```

This checks: dependencies installed, versions compatible, shadcn configured, components present.

### Step 2: Identify the Symptom

| Symptom | Likely Cause | Go To |
|---------|-------------|-------|
| Component renders but shows nothing | Missing server-side flag | Step 3 |
| Markdown is unstyled / raw text | Missing Streamdown CSS | Step 4 |
| No auto-scroll in chat | Missing Conversation wrapper or no fixed height | Step 5 |
| Tool calls show as raw JSON | Not using Tool component for tool-invocation parts | Step 6 |
| Reasoning not showing | Missing `sendReasoning: true` | Step 3 |
| Sources not showing | Missing `sendSources: true` | Step 3 |
| Hydration errors | Missing `"use client"` directive | Step 7 |
| Streaming feels broken/static | Not wired to useChat | Step 8 |
| Import errors | Component not installed | Step 9 |

### Step 3: Missing Server-Side Flags

Check the API route file (usually `app/api/chat/route.ts`):

```ts
// Must include these flags as needed:
return result.toUIMessageStreamResponse({
  sendReasoning: true,  // Required for Reasoning
  sendSources: true,    // Required for Sources
});

// For tool approval:
tools: {
  myTool: {
    requireApproval: true, // Required for Confirmation
  }
}
```

See `references/rules.md` → R7 for the full table.

### Step 4: Missing Streamdown CSS

Verify the CSS import exists in your layout or page:
```tsx
import "@streamdown/styles"; // exact import may vary
```

Check the Streamdown docs linked in the Message component documentation.

### Step 5: Conversation Scroll Issues

Verify:
1. `Conversation` is wrapped in a container with explicit height
2. `ConversationContent` is the direct child
3. `ConversationScrollButton` is inside `Conversation` (not outside)

```tsx
<div className="h-[600px]"> {/* Fixed height required */}
  <Conversation>
    <ConversationContent>...</ConversationContent>
    <ConversationScrollButton />
  </Conversation>
</div>
```

### Step 6: Tool Calls as Raw JSON

Ensure you're switching on `message.parts` and rendering Tool for `tool-invocation`:

```tsx
case "tool-invocation":
  return <Tool toolPart={part} />;
```

### Step 7: Hydration Errors

Add `"use client"` to the top of any file using:
- `useChat`, `useState`, `useEffect`, or any React hook
- AI Elements components that use hooks internally

### Step 8: Static/Not Streaming

Verify:
1. `useChat()` is called and connected
2. `sendMessage()` is used (not a manual fetch)
3. The API route returns `result.toUIMessageStreamResponse()`
4. `status` from useChat is passed to components

### Step 9: Import Errors

Run:
```bash
bash scripts/search-component.sh {{PROJECT_ROOT}} {{COMPONENT}}
```

If not found, install it:
```bash
npx ai-elements@latest add {{COMPONENT}}
```

### Step 10: Still Stuck

1. Check the docs: https://elements.ai-sdk.dev/docs/troubleshooting
2. Check GitHub issues: https://github.com/vercel/ai-elements/issues
3. Check AI SDK docs: https://ai-sdk.dev
