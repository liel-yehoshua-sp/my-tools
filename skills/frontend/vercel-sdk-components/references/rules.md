# AI Elements — Rules

These are hard rules that MUST NOT be violated when using AI Elements.

## R1: Never Use Without AI SDK

AI Elements components MUST be used with the Vercel AI SDK (`@ai-sdk/react`). Components without `useChat` will not function correctly for streaming, tool calls, or reasoning.

**Exception**: Static demos or storybook previews with mocked data.

## R2: Always Import Streamdown CSS

When using `MessageResponse`, the Streamdown CSS MUST be imported. Without it, streaming markdown will be unstyled.

## R3: Use "use client" Directive

All components that use hooks (`useChat`, `useState`, etc.) MUST have `"use client"` at the top of the file. AI Elements are client components.

## R4: Don't Modify AI Elements Source for Bug Fixes

If you find a bug in an AI Elements component, don't patch it inline. Instead:
1. Report it at https://github.com/vercel/ai-elements/issues
2. Create a wrapper component with the fix
3. Update when the fix is released

**Exception**: Customization of styling, layout, or adding features on top is fine.

## R5: Conversation Requires Fixed Height

The `Conversation` component MUST be placed inside a container with a defined height. Without it, auto-scroll will not work.

## R6: Message Parts Over Content

Always iterate `message.parts` and switch on `part.type`. Do NOT use `message.content` directly — it may not contain tool calls, reasoning, or sources.

## R7: Server Route Must Match Component

| Component | Server Requirement |
|---|---|
| Reasoning | `sendReasoning: true` in `toUIMessageStreamResponse()` |
| Sources | `sendSources: true` in `toUIMessageStreamResponse()` |
| Confirmation | `requireApproval: true` on tool definition |
| Tool | Tool must be defined in `streamText({ tools: {...} })` |

Forgetting the server-side flag is the #1 cause of "component renders but shows nothing".

## R8: Don't Mix AI Elements With Competing Libraries

Do NOT use AI Elements alongside assistant-ui or other AI chat UI libraries in the same feature. Pick one. They manage overlapping state and will conflict.

## R9: Node.js 18+ Required

AI Elements requires Node.js 18 or later. The CLI will fail on older versions.

## R10: CSS Variables Mode Only

AI Elements requires shadcn/ui's CSS Variables mode. It does NOT support Tailwind class-based theming.
