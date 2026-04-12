# Image

- **Category**: Utilities
- **Docs**: [https://elements.ai-sdk.dev/components/image](https://elements.ai-sdk.dev/components/image)
- **Install**: `npx ai-elements@latest add image`

## Description

Display AI-generated images with loading states, error handling, and alt text. Supports DALL-E, Midjourney, and other image generation outputs.

## Tags

`image, ai-generated, loading, error, dall-e, midjourney, preview`

## Scenarios

### ✅ Good Fit

- Displaying DALL-E or other AI-generated images in chat
- Showing image generation progress with loading state
- Handling image generation errors gracefully

### ❌ Bad Fit (with alternatives)

- Image galleries → Use a dedicated gallery library
- Image editing → Use Canvas API or image editing library
- Static images → Use Next.js Image component

## Testing Checklist

- [ ] Loading state renders placeholder
- [ ] Image renders when URL is available
- [ ] Error state renders fallback
- [ ] Alt text is accessible
- [ ] Responsive sizing
