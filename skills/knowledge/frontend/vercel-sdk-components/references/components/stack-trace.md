# Stack Trace

- **Category**: Code
- **Docs**: [https://elements.ai-sdk.dev/components/stack-trace](https://elements.ai-sdk.dev/components/stack-trace)
- **Install**: `npx ai-elements@latest add stack-trace`

## Description

Error stack trace display with file paths and line numbers.

## Tags

`stack-trace, error, exception, debug, crash, traceback`

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
