# Conversation

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/conversation](https://elements.ai-sdk.dev/components/conversation)
- **Install**: `npx ai-elements@latest add conversation`

### Sub-components

| Sub-component | Purpose |
|---|---|
| Conversation | Root scroll container |
| ConversationContent | Content area inside the scroller |
| ConversationScrollButton | Scroll-to-bottom FAB |
| ConversationEmptyState | Empty state (icon, title, description) |
| ConversationDownload | Download-as-markdown button |
| messagesToMarkdown() | Utility to convert messages to markdown string |

## Description

Wraps messages and automatically scrolls to the bottom when new messages arrive. Includes a scroll-to-bottom button that appears when the user scrolls up, an empty state display, and a download-as-markdown utility. Designed to be the outermost container for any chat UI.

## Tags

`chat, container, scroll, auto-scroll, download, empty-state, conversation`

## Scenarios

### ✅ Good Fit

- Wrapping a list of Message components in a chat interface
- Auto-scrolling to latest message during streaming
- Showing an empty state before the first message
- Providing a scroll-to-bottom button for long conversations
- Exporting/downloading conversation as Markdown

### ❌ Bad Fit (with alternatives)

- **Non-chat scrollable lists** → Use standard overflow-auto containers
- **Message persistence/history** → This is UI only; use a database or AI SDK chat history
- **Multi-panel layouts** → Use CSS grid/flex; Conversation is a single scroll container

## Testing Checklist

- [ ] Auto-scrolls to bottom when new messages are added
- [ ] Auto-scroll works during streaming (partial message updates)
- [ ] Scroll-to-bottom button appears when user scrolls up
- [ ] Scroll-to-bottom button disappears when at bottom
- [ ] Empty state renders when no messages
- [ ] Download button exports conversation as valid Markdown
- [ ] Works correctly inside flex/grid layouts with fixed height
- [ ] Smooth scrolling animation is not janky
