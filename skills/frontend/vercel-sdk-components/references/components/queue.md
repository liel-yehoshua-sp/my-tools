# Queue

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/queue](https://elements.ai-sdk.dev/components/queue)
- **Install**: `npx ai-elements@latest add queue`

## Description

Task queue with collapsible sections for organizing pending and completed items with status indicators.

## Tags

`queue, tasks, pending, completed, sections, status, kanban`

## Scenarios

### ✅ Good Fit

- Organizing pending vs completed tasks
- Building IDE task queues
- Showing background job status
- Managing multiple concurrent AI tasks

### ❌ Bad Fit (with alternatives)

- Simple lists (use shadcn list)
- Kanban boards (use dnd-kit based solutions)
- Notification queues (use Toast)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
