# Suggestion

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/suggestion](https://elements.ai-sdk.dev/components/suggestion)
- **Install**: `npx ai-elements@latest add suggestion`

## Description

A horizontal row of clickable suggestion chips for user interaction. Users click to send the suggestion as a message.

## Tags

`suggestion, chips, quick-replies, prompts, starter, clickable`

## Scenarios

### ✅ Good Fit

- Showing starter prompts in empty chat state
- Offering follow-up suggestions after responses
- Building quick-reply chips
- Onboarding users with example queries

### ❌ Bad Fit (with alternatives)

- Navigation menus (use shadcn Navigation)
- Tag selection (use shadcn Badge)
- Filter chips (use shadcn Toggle)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
