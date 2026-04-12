# File Tree

- **Category**: Code
- **Docs**: [https://elements.ai-sdk.dev/components/file-tree](https://elements.ai-sdk.dev/components/file-tree)
- **Install**: `npx ai-elements@latest add file-tree`

## Description

Hierarchical file system navigation with expandable folders and file selection. Supports controlled expanded/selected state.

## Tags

`file-tree, files, folders, navigation, hierarchy, explorer, sidebar`

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
