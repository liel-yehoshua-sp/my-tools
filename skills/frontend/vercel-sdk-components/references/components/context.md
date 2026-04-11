# Context

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/context](https://elements.ai-sdk.dev/components/context)
- **Install**: `npx ai-elements@latest add context`

## Description

Displays contextual information within conversations, such as relevant data or background information.

## Tags

`context, background, info, metadata, relevant-data`

## Scenarios

### ✅ Good Fit

- Showing context used by the AI to generate responses
- Displaying relevant documents or data snippets
- Providing background information in chat

### ❌ Bad Fit (with alternatives)

- Static info banners (use shadcn Alert)
- Help text (use shadcn Tooltip)
- Settings display (use custom components)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
