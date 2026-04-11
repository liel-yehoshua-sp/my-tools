# Chain of Thought

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/chain-of-thought](https://elements.ai-sdk.dev/components/chain-of-thought)
- **Install**: `npx ai-elements@latest add chain-of-thought`

## Description

A collapsible component visualizing AI reasoning steps with search results, images, and progress indicators. Best for models that emit discrete labeled steps. For continuous reasoning streams, use Reasoning instead.

## Tags

`chain-of-thought, steps, search, reasoning, progress, thinking`

## Scenarios

### ✅ Good Fit

- Displaying multi-step reasoning with labeled stages
- Showing search queries and results during reasoning
- Rendering images found during research
- Visualizing step-by-step problem solving

### ❌ Bad Fit (with alternatives)

- Continuous reasoning streams (use Reasoning instead)
- Simple loading indicators (use Shimmer)
- Static step lists (use shadcn Stepper or custom)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
