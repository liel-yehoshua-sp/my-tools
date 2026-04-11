# Code Block

- **Category**: Code
- **Docs**: [https://elements.ai-sdk.dev/components/code-block](https://elements.ai-sdk.dev/components/code-block)
- **Install**: `npx ai-elements@latest add code-block`

## Description

Syntax-highlighted code display with line numbers, copy-to-clipboard, filename header, and language selector. Fully composable. Wrap in a div with 'dark' class for dark mode.

## Tags

`code, syntax, highlighting, copy, line-numbers, programming, dark-mode`

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
