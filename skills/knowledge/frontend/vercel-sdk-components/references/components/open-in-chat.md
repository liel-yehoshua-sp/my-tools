# Open In Chat

- **Category**: Utilities
- **Docs**: [https://elements.ai-sdk.dev/components/open-in-chat](https://elements.ai-sdk.dev/components/open-in-chat)
- **Install**: `npx ai-elements@latest add open-in-chat`

## Description

A button component that opens content in the chat context, allowing users to reference or discuss content from other parts of the UI in the chat.

## Tags

`open-in-chat, reference, context, button, share`

## Scenarios

### ✅ Good Fit

- Adding "discuss this" buttons to content outside the chat
- Letting users reference artifacts, code, or data in chat
- Building multi-panel UIs where content feeds into chat

### ❌ Bad Fit (with alternatives)

- Simple share buttons → Use shadcn Button
- Copy to clipboard → Use a copy button
- Navigation → Use Next.js Link

## Testing Checklist

- [ ] Button renders correctly
- [ ] Click sends content to chat context
- [ ] Works across different content types
