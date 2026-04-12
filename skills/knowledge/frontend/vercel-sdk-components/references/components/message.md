# Message

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/message](https://elements.ai-sdk.dev/components/message)
- **Install**: `npx ai-elements@latest add message`

### Sub-components

| Sub-component | Purpose |
|---|---|
| Message | Root container, accepts `from` (user/assistant) |
| MessageContent | Content wrapper |
| MessageResponse | Streaming markdown renderer (requires Streamdown CSS) |
| MessageActions | Action button toolbar |
| MessageAction | Individual action button |
| MessageBranch | Branching container |
| MessageBranchSelector | Branch navigation UI |
| MessageBranchPrevious/Next | Navigation buttons |
| MessageBranchPage | Current page indicator |
| MessageBranchContent | Branch content wrapper |

## Description

A comprehensive suite of components for displaying chat messages. Includes message rendering with user/assistant styling, response branching (navigate between regenerated responses), action buttons (retry, copy, like, dislike, share), file attachments display, and streaming markdown rendering via MessageResponse (powered by Streamdown). MessageResponse requires importing Streamdown CSS for proper styling. Supports GFM tables, task lists, math equations, and code blocks with syntax highlighting.

## Tags

`chat, message, bubble, markdown, streaming, branching, actions, copy, retry, like, dislike, attachments`

## Scenarios

### ✅ Good Fit

- Displaying user and assistant messages in a chat interface
- Rendering streaming markdown responses from LLMs
- Adding copy/retry/like/dislike actions to assistant messages
- Showing file attachments (images, documents) in messages
- Navigating between multiple regenerated responses (branching)
- Rendering code blocks within assistant responses

### ❌ Bad Fit (with alternatives)

- **Static content display** (not from LLM) → Use standard shadcn Card or Typography components
- **Rich text editing** → Use a rich text editor like TipTap or Plate
- **Email/notification messages** → Use shadcn Alert or Toast components
- **Standalone markdown rendering** (no chat context) → Use a markdown renderer directly

## Testing Checklist

- [ ] MessageResponse renders streaming markdown without flickering
- [ ] Streamdown CSS is imported (required for MessageResponse)
- [ ] User and assistant messages render with correct styling (`from` prop)
- [ ] Action buttons (copy, retry, like, dislike) trigger correct callbacks
- [ ] File attachments render previews for images and icons for other files
- [ ] Branching navigation shows correct page count and switches content
- [ ] Code blocks within responses have syntax highlighting and copy button
- [ ] Message renders correctly with empty content
- [ ] Long messages don't break layout
