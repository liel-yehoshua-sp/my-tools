# Plan

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/plan](https://elements.ai-sdk.dev/components/plan)
- **Install**: `npx ai-elements@latest add plan`

## Description

A collapsible plan component for displaying AI-generated execution plans with streaming support and shimmer loading animations.

## Tags

`plan, execution, steps, workflow, strategy, shimmer, collapsible`

## Scenarios

### ✅ Good Fit

- Displaying multi-step implementation strategies
- Showing AI task breakdown before execution
- Building IDE-like plan views
- Streaming plan content as it generates

### ❌ Bad Fit (with alternatives)

- Simple to-do lists (use shadcn Checkbox list)
- Static documentation (use markdown)
- Progress tracking (use Queue or Task)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
