# Attachments

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/attachments](https://elements.ai-sdk.dev/components/attachments)
- **Install**: `npx ai-elements@latest add attachments`

## Description

File attachment display with support for images and generic files. Includes preview thumbnails and remove buttons. Moved to a separate module from PromptInput.

## Tags

`attachments, files, upload, images, preview, remove, drag-drop`

## Scenarios

### ✅ Good Fit

- Displaying uploaded files in the chat input
- Showing image previews for attached images
- Allowing users to remove attached files
- Building multi-file upload UIs

### ❌ Bad Fit (with alternatives)

- File managers (use custom file browser)
- Image galleries (use dedicated gallery)
- Document viewers (use PDF/doc viewers)

## Testing Checklist

- [ ] Component renders correctly with valid props
- [ ] Component handles empty/missing data gracefully
- [ ] Component integrates correctly with useChat hook
- [ ] Streaming states render properly
- [ ] Responsive layout works at various viewport sizes
- [ ] Accessibility: keyboard navigation and screen reader support
- [ ] Theme: respects shadcn/ui CSS variables (light/dark mode)
