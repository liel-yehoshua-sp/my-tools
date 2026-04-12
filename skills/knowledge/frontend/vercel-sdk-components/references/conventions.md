# AI Elements — Conventions

## File Structure

AI Elements components are installed to `@/components/ai-elements/` by default:

```
components/
├── ai-elements/
│   ├── message.tsx
│   ├── conversation.tsx
│   ├── prompt-input.tsx
│   ├── reasoning.tsx
│   ├── tool.tsx
│   └── ...
└── ui/          # shadcn/ui base components
    ├── button.tsx
    └── ...
```

Do NOT move AI Elements components out of this directory. Other components reference them by this path.

## Import Convention

```tsx
// ✅ Always import from @/components/ai-elements/<component>
import { Message, MessageContent, MessageResponse } from "@/components/ai-elements/message";
import { Conversation, ConversationContent } from "@/components/ai-elements/conversation";

// ❌ Never import from node_modules (there are none — it's copy-pasted code)
```

## Naming Convention

- Component files: kebab-case (`prompt-input.tsx`, `chain-of-thought.tsx`)
- Component names: PascalCase (`PromptInput`, `ChainOfThought`)
- Sub-components: PrefixedPascalCase (`MessageContent`, `MessageResponse`, `MessageActions`)
- Hooks: camelCase with `use` prefix (`useChat`, `useReasoningContext`, `usePromptInputAttachments`)

## Composition Convention

AI Elements uses a compound component pattern. The root component provides context, children consume it:

```tsx
<Conversation>          {/* Root: provides scroll context */}
  <ConversationContent> {/* Content: scrollable area */}
    <Message>           {/* Individual message */}
      <MessageContent>  {/* Message body */}
        ...
      </MessageContent>
    </Message>
  </ConversationContent>
  <ConversationScrollButton /> {/* Scroll FAB */}
</Conversation>
```

## API Route Convention

API routes for AI chat follow this pattern:

```
app/api/chat/route.ts          # Default chat endpoint
app/api/weather/route.ts       # Tool-specific endpoints
app/api/sources/route.ts       # Search-augmented endpoint
```

Always use `POST` method and return `result.toUIMessageStreamResponse()`.

## State Management Convention

- Use `useChat` from `@ai-sdk/react` as the single source of truth
- Don't duplicate message state in local state
- Use `PromptInputProvider` to share input state when needed across components
- Use `DefaultChatTransport` for custom API endpoints

## CSS Convention

- Use shadcn/ui CSS Variables mode (not Tailwind classes for theming)
- AI Elements respects your existing shadcn theme
- Don't override AI Elements internal styles with `!important`
- Use `className` prop for layout customization (margin, padding, width)
