# Checkpoint

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/checkpoint](https://elements.ai-sdk.dev/components/checkpoint)
- **Install**: `npx ai-elements@latest add checkpoint`

## Description

A component for saving and restoring conversation states. Allows users to mark points in the conversation and restore to them later.

## Tags

`checkpoint, save, restore, conversation-state, undo, history`

## Scenarios

### ✅ Good Fit

- Saving conversation state at key points
- Allowing users to revert to earlier states
- Building undo/redo for conversations
- Version control for chat threads

### ❌ Bad Fit (with alternatives)

- General undo/redo in forms (use state management)
- File versioning (use git)
- Session persistence (use database)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
