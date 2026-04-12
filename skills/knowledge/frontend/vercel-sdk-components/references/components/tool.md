# Tool

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/tool](https://elements.ai-sdk.dev/components/tool)
- **Install**: `npx ai-elements@latest add tool`

### Sub-components

| Sub-component | Purpose |
|---|---|
| Tool | Root collapsible container |
| ToolContent | Content wrapper |
| ToolHeader | Header with tool name and status badge |
| ToolInput | Input parameters display |
| ToolOutput | Output/result display |
| getStatusBadge() | Utility returning Badge by state |

## Description

A collapsible component for displaying tool invocation details in AI chat interfaces. Shows the tool name, state (calling, result, error), input parameters, and output. Designed to consume the ToolUIPart type from the AI SDK directly. Includes a getStatusBadge() utility for rendering state badges.

## Tags

`tool, function-call, tool-invocation, tool-result, tool-call, collapsible, status, badge`

## Scenarios

### ✅ Good Fit

- Displaying tool calls made by the AI (e.g., weather lookup, file operations)
- Showing tool input parameters and output results
- Rendering tool execution state (calling, success, error)
- Building custom tool UI renderers per tool name
- Displaying JSON output using CodeBlock inside Tool

### ❌ Bad Fit (with alternatives)

- **User-initiated actions** → Use shadcn Button + Dialog
- **Form submissions** → Use shadcn Form
- **Tool approval workflows** → Use [Confirmation](confirmation.md) instead
- **Multiple tools in a pipeline** → Use [Plan](plan.md) for the overview + Tool for each step

## Testing Checklist

- [ ] Tool renders correctly for each state: calling, output-available, error
- [ ] Collapsible toggle works
- [ ] ToolInput displays input parameters
- [ ] ToolOutput displays results (text, JSON, or custom)
- [ ] Error state shows error message clearly
- [ ] getStatusBadge() returns correct badge for each state
- [ ] Works with typed ToolUIPart generics for type-safe tool rendering
- [ ] Loading state shows spinner/indicator while tool is executing
