# Prompt Input

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/prompt-input](https://elements.ai-sdk.dev/components/prompt-input)
- **Install**: `npx ai-elements@latest add prompt-input`

### Sub-components

| Sub-component | Purpose |
|---|---|
| PromptInput | Root container, `onSubmit` handler |
| PromptInputTextarea | Auto-resizing textarea |
| PromptInputSubmit | Submit button with status |
| PromptInputBody/Header/Footer | Layout sections |
| PromptInputButton | Toolbar button with optional tooltip |
| PromptInputTools | Toolbar container |
| PromptInputSelect | Dropdown (for model selection) |
| PromptInputActionMenu | Action menu (attachments, screenshot) |
| PromptInputProvider | State provider for external access |
| usePromptInputAttachments() | Hook for attachment management |

## Description

A rich input area for sending messages to LLMs. Includes auto-resizing textarea, file upload (via action menu), model selection dropdown, submit button with streaming status, screenshot capture, toolbar buttons with tooltips and keyboard shortcuts, and a provider pattern (PromptInputProvider) for lifting state outside the component. Supports the PromptInputMessage type for handling text + file attachments together.

## Tags

`input, textarea, submit, attachments, upload, model-picker, prompt, send, toolbar, shortcuts`

## Scenarios

### ✅ Good Fit

- Building the main chat input area with send button
- Adding file upload capabilities to the input
- Integrating a model selector dropdown in the input
- Adding toolbar buttons (web search toggle, voice toggle)
- Displaying keyboard shortcut hints on buttons
- Lifting input state to parent components via PromptInputProvider
- Using usePromptInputAttachments() hook for attachment management

### ❌ Bad Fit (with alternatives)

- **Simple text input** (no AI context) → Use shadcn Input or Textarea
- **Form submissions** → Use shadcn Form components with react-hook-form
- **Search bar** → Use shadcn Command or Input with search styling
- **Code editor input** → Use CodeMirror or Monaco editor

## Testing Checklist

- [ ] Textarea auto-resizes as content grows
- [ ] Submit button reflects streaming status (disabled during streaming)
- [ ] File attachments can be added via action menu
- [ ] Attached files show preview and can be removed
- [ ] Model selector dropdown works and passes selected model
- [ ] Keyboard shortcuts (Cmd+Enter to submit) work
- [ ] PromptInputProvider correctly lifts state to parent
- [ ] usePromptInputAttachments() hook manages files correctly
- [ ] Empty submission is prevented
- [ ] Works with useChat's sendMessage function
