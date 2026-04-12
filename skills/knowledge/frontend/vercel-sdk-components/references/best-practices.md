# AI Elements — Best Practices

## 1. Always Wire to useChat

AI Elements components are designed to consume AI SDK hook output. The core pattern is:

```tsx
const { messages, sendMessage, status } = useChat();
```

Never render Message/Conversation/Reasoning without connecting to `useChat`. Standalone usage produces static, broken UIs.

## 2. Use message.parts, Not message.content

The AI SDK v5+ uses a parts-based message structure. Always iterate over `message.parts` and switch on `part.type`:

```tsx
{message.parts.map((part, i) => {
  switch (part.type) {
    case "text":
      return <MessageResponse key={i}>{part.text}</MessageResponse>;
    case "reasoning":
      return <Reasoning key={i}>...</Reasoning>;
    case "tool-invocation":
      return <Tool key={i} toolPart={part} />;
    case "source":
      return <Source key={i} source={part} />;
    default:
      return null;
  }
})}
```

## 3. Import Streamdown CSS

MessageResponse uses Streamdown for streaming markdown. You MUST import the CSS:

```tsx
import "@streamdown/styles"; // or the appropriate CSS import
```

Without it, markdown rendering will be unstyled.

## 4. Composable Over Monolithic

AI Elements follows shadcn/ui's composable pattern. Don't try to use a single mega-component — compose sub-components:

```tsx
// ✅ Good: composable
<Message from="assistant">
  <MessageContent>
    <MessageResponse>{text}</MessageResponse>
  </MessageContent>
  <MessageActions>
    <MessageAction onClick={handleCopy}><CopyIcon /></MessageAction>
  </MessageActions>
</Message>

// ❌ Bad: trying to pass everything as props
<Message content={text} actions={[...]} from="assistant" />
```

## 5. Server Route Configuration

Different AI features require different server-side flags:

```ts
return result.toUIMessageStreamResponse({
  sendReasoning: true,  // For Reasoning component
  sendSources: true,    // For Sources component
});
```

For tool approval:
```ts
tools: {
  myTool: {
    requireApproval: true, // For Confirmation component
    // ...
  }
}
```

## 6. Status-Aware Rendering

Use `status` from `useChat` to conditionally render loading states:

```tsx
const { status } = useChat();
// status: "ready" | "submitted" | "streaming" | "error"
```

Pass status to PromptInputSubmit and use it to show Shimmer or loading indicators.

## 7. Component Boundaries

Each component should handle one concern:
- Conversation = scrolling container
- Message = individual message bubble
- MessageResponse = markdown rendering
- Tool = tool call display
- Reasoning = thinking display

Don't merge responsibilities.

## 8. Dark Mode

For CodeBlock, wrap in a div with `dark` class for dark mode. Other components respect shadcn CSS variables automatically.

## 9. Conversation Height

Conversation needs a fixed height container to scroll properly:

```tsx
// ✅ Good
<div className="h-[600px]">
  <Conversation>...</Conversation>
</div>

// ❌ Bad: no height constraint
<Conversation>...</Conversation>
```

## 10. Type Safety

Use the AI SDK's TypeScript types:

```tsx
import type { UIMessage } from "ai";
import type { ToolUIPart } from "ai";
```

Use generics with ToolUIPart for type-safe tool rendering:
```tsx
type MyToolPart = ToolUIPart<{
  my_tool: { input: MyInput; output: MyOutput };
}>;
```
