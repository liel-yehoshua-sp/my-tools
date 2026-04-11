# Sandbox

- **Category**: Code
- **Docs**: [https://elements.ai-sdk.dev/components/sandbox](https://elements.ai-sdk.dev/components/sandbox)
- **Install**: `npx ai-elements@latest add sandbox`

## Description

Collapsible container for AI-generated code alongside execution output. Features tabs for code/output views and status indicators. Designed to work with CodeBlock and StackTrace.

## Tags

`sandbox, code-execution, output, tabs, run, status, ide`

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
