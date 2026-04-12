# Sources

- **Category**: Chatbot
- **Docs**: [https://elements.ai-sdk.dev/components/sources](https://elements.ai-sdk.dev/components/sources)
- **Install**: `npx ai-elements@latest add sources`

### Sub-components

| Sub-component | Purpose |
|---|---|
| Sources | Root collapsible container |
| SourcesContent | Content wrapper |
| SourcesTrigger | Toggle trigger with count |
| Source | Individual source item |

### Server-side requirement

```ts
return result.toUIMessageStreamResponse({ sendSources: true });
```

## Description

A collapsible component that displays the sources/citations used to generate a response. Best used with search-augmented models like Perplexity Sonar. Integrates with AI SDK's sendSources: true.

## Tags

`sources, citations, references, perplexity, search, grounding, RAG`

## Scenarios

### ✅ Good Fit

- Displaying web sources from Perplexity Sonar responses
- Showing RAG retrieval sources
- Rendering citation lists for grounded AI responses
- Building research assistant UIs with source transparency

### ❌ Bad Fit (with alternatives)

- **Inline clickable citations** → Use [InlineCitation](inline-citation.md) instead
- **Bibliography/reference lists** → Build custom list component
- **Footnotes** → Use standard markdown footnotes in MessageResponse

## Testing Checklist

- [ ] Sources render as a collapsible list
- [ ] Each source shows title and URL
- [ ] Source links are clickable and open correctly
- [ ] Works with sendSources: true on server route
- [ ] Handles empty source list gracefully
- [ ] Trigger shows source count
