# Shimmer

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/shimmer](https://elements.ai-sdk.dev/components/shimmer)
- **Install**: `npx ai-elements@latest add shimmer`

## Description

Loading placeholder animation for streaming content. Shows animated shimmer effect while content loads.

## Tags

`shimmer, loading, skeleton, placeholder, animation, streaming`

## Scenarios

### ✅ Good Fit

- Showing loading state while AI response streams
- Placeholder for plan content loading
- Skeleton loading for any AI element

### ❌ Bad Fit (with alternatives)

- Page-level skeleton loading (use shadcn Skeleton)
- Spinner indicators (use shadcn Spinner)
- Progress bars (use shadcn Progress)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
