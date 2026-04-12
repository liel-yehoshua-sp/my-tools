# Terminal

- **Category**: Code
- **Docs**: [https://elements.ai-sdk.dev/components/terminal](https://elements.ai-sdk.dev/components/terminal)
- **Install**: `npx ai-elements@latest add terminal`

## Description

Terminal output display with ANSI color code support for build output, test results, and command output.

## Tags

`terminal, console, output, ansi, cli, build, logs`

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
