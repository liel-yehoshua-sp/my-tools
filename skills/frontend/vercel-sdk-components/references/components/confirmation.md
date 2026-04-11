# Confirmation

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/confirmation](https://elements.ai-sdk.dev/components/confirmation)
- **Install**: `npx ai-elements@latest add confirmation`

### Sub-components

| Sub-component | Purpose |
|---|---|
| Confirmation | Root container |
| ConfirmationRequest | Pending approval content |
| ConfirmationAccepted | Post-approval content |
| ConfirmationRejected | Post-rejection content |
| ConfirmationActions | Action button container |
| ConfirmationAction | Individual approve/reject button |

## Description

An alert-based component for managing tool execution approval workflows. Displays request, accept, and reject states. Integrates with AI SDK's requireApproval: true and addToolApprovalResponse for human-in-the-loop tool execution.

## Tags

`confirmation, approval, human-in-the-loop, tool-approval, accept, reject, dangerous-action`

## Scenarios

### ✅ Good Fit

- Requiring user approval before executing destructive tools (delete, modify)
- Human-in-the-loop approval for sensitive operations
- Showing approval status (pending, approved, rejected)
- Integrating with AI SDK's tool approval workflow

### ❌ Bad Fit (with alternatives)

- **Simple yes/no dialogs** → Use shadcn AlertDialog
- **Form confirmations** → Use shadcn Dialog with form
- **Non-tool-related confirmations** → Use shadcn AlertDialog
- **Multi-step approval** → Build custom workflow with [Plan](plan.md)

## Testing Checklist

- [ ] Request state shows the approval prompt with action details
- [ ] Accept and Reject buttons trigger addToolApprovalResponse correctly
- [ ] Accepted state renders ConfirmationAccepted content
- [ ] Rejected state renders ConfirmationRejected content
- [ ] Works with requireApproval: true on the server tool definition
- [ ] Tool executes only after approval
- [ ] UI updates correctly after approval/rejection
