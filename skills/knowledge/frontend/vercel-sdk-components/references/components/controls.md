# Controls

- **Category**: Workflow
- **Docs**: [https://elements.ai-sdk.dev/components/controls](https://elements.ai-sdk.dev/components/controls)
- **Install**: `npx ai-elements@latest add controls`

## Description

Zoom, pan, and fit controls for the workflow canvas.

## Tags

`controls, zoom, pan, fit, navigation`

## Scenarios

### ✅ Good Fit

- Building visual workflow/pipeline editors
- Creating agent orchestration UIs
- Node-based AI flow builders

### ❌ Bad Fit (with alternatives)

- Full-featured flow editors → Use React Flow or dagre directly
- Simple flowcharts → Use Mermaid diagrams
- Static diagrams → Use SVG or d3

## Testing Checklist

- [ ] Component renders correctly on the canvas
- [ ] Zoom, pan, and fit controls work
- [ ] Nodes can be positioned and connected
- [ ] Responsive to canvas resizing
- [ ] Touch/mobile interactions work
