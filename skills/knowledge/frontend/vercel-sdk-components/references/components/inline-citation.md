# Inline Citation

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/inline-citation](https://elements.ai-sdk.dev/components/inline-citation)
- **Install**: `npx ai-elements@latest add inline-citation`

## Description

Hoverable inline citations within text, similar to Perplexity AI. Shows preview on hover.

## Tags

`citation, inline, hover, preview, perplexity, reference, footnote`

## Scenarios

### ✅ Good Fit

- Adding numbered inline citations within AI responses
- Showing source preview on hover
- Building Perplexity-style search UIs

### ❌ Bad Fit (with alternatives)

- Source lists at end of message (use Sources instead)
- Static footnotes (use markdown)
- Bibliography pages (use custom components)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
