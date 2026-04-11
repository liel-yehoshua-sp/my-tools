# Task

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/task](https://elements.ai-sdk.dev/components/task)
- **Install**: `npx ai-elements@latest add task`

## Description

Task display with file references, status indicators, and collapsible content.

## Tags

`task, status, file-reference, progress, collapsible`

## Scenarios

### ✅ Good Fit

- Showing individual task status in an IDE
- Displaying task with associated file changes
- Building task detail views

### ❌ Bad Fit (with alternatives)

- Simple checkboxes (use shadcn Checkbox)
- To-do apps (use custom components)
- Project management (use dedicated tools)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
