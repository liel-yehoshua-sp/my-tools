# Model Selector

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/model-selector](https://elements.ai-sdk.dev/components/model-selector)
- **Install**: `npx ai-elements@latest add model-selector`

## Description

Searchable dropdown for selecting AI models. Shows provider logos, model names, and supports keyboard navigation.

## Tags

`model, selector, dropdown, provider, openai, anthropic, google, search`

## Scenarios

### ✅ Good Fit

- Letting users pick which AI model to use
- Showing available models grouped by provider
- Filtering models by name or provider

### ❌ Bad Fit (with alternatives)

- Static model configuration (use env vars)
- Backend-only model selection (no UI needed)
- Simple select dropdowns (use shadcn Select)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
