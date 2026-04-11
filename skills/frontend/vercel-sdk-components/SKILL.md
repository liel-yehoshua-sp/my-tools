---
name: vercel-sdk-components
version: "1.0.0"
last_updated: "2026-03-29"
description: >
  Specialized skill for Vercel AI Elements — a component library built on shadcn/ui for AI-native applications.
  Use this skill whenever the user wants to build AI chat interfaces, streaming UIs, reasoning displays,
  tool call renderers, code sandbox views, voice interfaces, or workflow editors using AI Elements components.
  Also trigger when the user mentions vercel-sdk-components, ai-elements, AI SDK UI components, elements.ai-sdk.dev, or wants to
  add AI/LLM UI components to a shadcn/Tailwind project. Trigger even for casual mentions like "add a chat UI",
  "show reasoning tokens", "render tool calls", "streaming markdown", or "AI chatbot components".
  This skill covers installation, component selection, integration patterns, best practices, and review workflows.
---

# vercel-sdk-components

> **Library**: [AI Elements](https://elements.ai-sdk.dev) by Vercel
> **GitHub**: [vercel/ai-elements](https://github.com/vercel/ai-elements)
> **Registry**: `https://elements.ai-sdk.dev/api/registry/`
> **Requires**: Next.js, AI SDK (`@ai-sdk/react`), shadcn/ui, Tailwind CSS

AI Elements is a component library and custom registry built on top of shadcn/ui for building AI-native applications. Components are copy-pasted into your codebase (no runtime dependency) and integrate deeply with the Vercel AI SDK's `useChat` hook for streaming, tool calls, and reasoning.

---

## Quick Reference

| Category   | Components | Use When |
|------------|-----------|----------|
| **Chatbot**   | Message, Conversation, PromptInput, Reasoning, ChainOfThought, Tool, Confirmation, Sources, InlineCitation, Suggestion, Attachments, Checkpoint, Context, ModelSelector, Plan, Queue, Shimmer, Task | Building chat interfaces, streaming responses, tool UIs |
| **Code**      | Agent, Artifact, CodeBlock, Commit, EnvironmentVariables, FileTree, JSXPreview, PackageInfo, Sandbox, SchemaDisplay, Snippet, StackTrace, Terminal, TestResults, WebPreview | Building IDE-like UIs, code display, execution environments |
| **Voice**     | AudioPlayer, MicSelector, Persona, SpeechInput, Transcription, VoiceSelector | Building voice agent interfaces |
| **Workflow**  | Canvas, Connection, Controls, Edge, Node, Panel, Toolbar | Building node-based visual flow editors |
| **Utilities** | Image, OpenInChat | Cross-cutting utilities |

→ Full component catalog: read `references/components.md`
→ Each component has its own file in `references/components/` with scenarios, tests, and details.

---

## Steps

### 1. Determine the workflow

Based on the user's request, pick the right workflow:

| User Intent | Workflow File |
|---|---|
| First time setup / new project | `workflows/installation.md` |
| Adding a specific component | `workflows/create-component.md` |
| Reviewing code changes | `workflows/review.md` |
| Upgrading / refactoring existing usage | `workflows/refactor.md` |
| Debugging issues | `workflows/troubleshooting.md` |

### 2. If adding or working with a component

1. Read `references/components.md` to find the right component
2. Read the component's detail file at `references/components/<component-name>.md`
3. Replace `{{COMPONENT}}` in workflow steps with the component name
4. Replace `{{COMPONENT_FILE}}` with the detail file path
5. Follow the workflow steps

### 3. Always validate

Before delivering code, run through:
- `references/best-practices.md` — Patterns to follow
- `references/conventions.md` — Naming and structure conventions
- `references/rules.md` — Hard rules that must not be violated

### 4. Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `scripts/search-component.sh` | Check if a component is already installed in the project | Before installing any component |
| `scripts/health-check.ts` | Validate AI Elements setup, versions, and configuration | On setup, after upgrades, when debugging |
| `scripts/list-usage.sh` | Find all usages of AI Elements components in a project | During review, refactor, or audit |

---

## Key Integration Pattern

AI Elements components are designed to consume AI SDK's `useChat` hook output. The core pattern is:

```
useChat() → message.parts → switch(part.type) → render AI Elements component
```

Supported part types: `text` → MessageResponse, `reasoning` → Reasoning, `tool-invocation` → Tool, `source` → Sources, `file` → Attachments.

Always wire components to the AI SDK — standalone usage without `useChat` will feel static and broken.

---

## Metadata

This skill auto-tracks its metadata. Update `version` and `last_updated` in the frontmatter when modifying.

| Field | Value |
|-------|-------|
| Library Version Tracked | AI Elements (ai-sdk.dev, March 2026) |
| AI SDK Compatibility | v5+ / v6 |
| shadcn/ui Compatibility | Latest (CSS Variables mode) |
| Node.js | 18+ |
