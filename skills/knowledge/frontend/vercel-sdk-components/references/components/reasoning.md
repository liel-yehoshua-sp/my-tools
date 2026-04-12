# Reasoning

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/reasoning](https://elements.ai-sdk.dev/components/reasoning)
- **Install**: `npx ai-elements@latest add reasoning`

### Sub-components

| Sub-component | Purpose |
|---|---|
| Reasoning | Root collapsible container |
| ReasoningContent | Content area |
| ReasoningTrigger | Toggle trigger (shows 'Thinking...' label) |
| useReasoningContext() | Hook to access reasoning state |

### Server-side requirement

Return reasoning tokens from your API route:
```ts
return result.toUIMessageStreamResponse({ sendReasoning: true });
```

## Description

A collapsible component that displays AI reasoning/thinking content. Automatically opens during streaming and collapses when finished. Best used with models that emit continuous reasoning streams like DeepSeek R1, Claude with extended thinking, or GPT with high reasoning effort. For models that emit discrete labeled steps, use ChainOfThought instead.

## Tags

`reasoning, thinking, chain-of-thought, collapsible, streaming, deepseek, claude-thinking, extended-thinking`

## Scenarios

### ✅ Good Fit

- Displaying DeepSeek R1 reasoning tokens
- Showing Claude extended thinking content
- Displaying GPT reasoning with high reasoning effort
- Consolidating multiple reasoning parts into a single block
- Auto-opening during streaming and auto-closing when done

### ❌ Bad Fit (with alternatives)

- **Discrete labeled steps** (search, tool calls, stages) → Use [ChainOfThought](chain-of-thought.md) instead
- **Static collapsible content** → Use shadcn Collapsible or Accordion
- **Debug/log output** → Use [Terminal](terminal.md) component
- **Execution plan display** → Use [Plan](plan.md) component

## Testing Checklist

- [ ] Auto-opens when streaming reasoning content starts
- [ ] Auto-closes when streaming finishes
- [ ] Manual toggle works (user can open/close)
- [ ] Multiple reasoning parts are consolidated into one block
- [ ] Works with sendReasoning: true on the server route
- [ ] Renders markdown content inside reasoning block
- [ ] Trigger shows elapsed time or 'Thinking...' indicator
- [ ] useReasoningContext() hook provides state to children
