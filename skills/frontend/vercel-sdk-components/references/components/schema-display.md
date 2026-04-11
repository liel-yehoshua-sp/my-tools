# Schema Display

- **Category**: Code
- **Docs**: [https://elements.ai-sdk.dev/components/schema-display](https://elements.ai-sdk.dev/components/schema-display)
- **Install**: `npx ai-elements@latest add schema-display`

## Description

Display data schemas (JSON Schema, Zod, etc.) in a readable format.

## Tags

`schema, json-schema, zod, types, display, data-model`

## Scenarios

### ✅ Good Fit

- Building IDE-like AI interfaces
- Displaying AI-generated code or output
- Creating coding assistant UIs
- Showing execution results in chat

### ❌ Bad Fit (with alternatives)

- Non-AI code display → Use a standalone code editor (Monaco, CodeMirror)
- General file management → Use OS-native file dialogs
- Production code editing → Use a full IDE solution

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Dark mode renders correctly (wrap in div with 'dark' class for CodeBlock)
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables
