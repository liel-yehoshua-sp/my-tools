---
name: frontend-rendering-performance
description: >-
  Frontend rendering knowledge: re-render boundaries, layout thrashing, images
  and Core Web Vitals, bundle size and code splitting, work on the render path,
  list virtualization, CSS containment and animation cost, loading placeholders
  and CLS. Use when building or tuning SPAs (React, Vue, Svelte, Solid, Angular,
  etc.), investigating LCP/INP/CLS, or choosing memoization and data-flow patterns.
---

# Frontend rendering performance

Reference for **main-thread work, layout, and delivery**. React examples below are illustrative; translate to your framework.

## Core principles

- **Colocate state** so expensive subtrees do not subscribe to volatile stores unnecessarily.
- **Measure before memoizing**: justify `memo` / callbacks with prop stability and real cost; compilers may obsolete manual memo.
- **Reserve space** for media, fonts, and async content to control CLS.

## Topics

### 1. Unnecessary re-renders

- **Signals**: Large subtrees update when unrelated parent state changes; unstable object/array/function props to memoized children; context value recreated every render; wrong hook dependency arrays.
- **Practices**: State colocation, split contexts, selector stores (e.g. Zustand selectors), `memo` + stable callbacks, correct `useMemo`/`useCallback` deps, move state down.

### 2. Layout thrashing

- **Signals**: Interleaved reads (`offsetWidth`, `getBoundingClientRect`) and writes in loops or rAF; forced synchronous layout.
- **Practices**: Batch reads then writes; separate rAF phases; avoid `flushSync` misuse; prefer transforms over layout-affecting properties where possible.

### 3. Images

- **Signals**: LCP-critical images without priority hints; below-fold without lazy loading; missing `srcset`/`sizes`; no modern formats where available; missing dimensions → layout shift.
- **Practices**: `loading`, `fetchpriority`, responsive srcset/sizes, AVIF/WebP/CDN formats, explicit width/height or aspect-ratio, framework image helpers.

### 4. Bundle size

- **Signals**: Whole lodash or icon fonts; barrel imports; CJS blocking tree-shaking; unnecessary polyfills; duplicates in graph.
- **Practices**: Per-function ESM imports, `modularizeImports`, `sideEffects: false` where valid, dynamic import for heavy rare features, analyzer in CI.

### 5. Code splitting

- **Signals**: All routes in main bundle; maps/editors/charts eager on first paint; large modal deps loaded upfront.
- **Practices**: Route and feature `lazy` / dynamic import / `next/dynamic` with loading UI and error boundaries; prefetch on intent.

### 6. Expensive render-path work

- **Signals**: Sort/filter/map large arrays every render; JSON parse/stringify in render; heavy regex or formatting in hot lists.
- **Practices**: `useMemo`/selectors, precompute in handlers, virtualize lists, workers or server for heavy derivation.

### 7. Long lists

- **Signals**: Thousands of rows mounted; unbounded chat/feed nodes; grids without windowing.
- **Practices**: `react-window`, TanStack Virtual, etc.; stable row height or ResizeObserver measurement; scroll restoration plan.

### 8. CSS cost

- **Signals**: Deep or universal selectors on large trees; heavy `:has()` on hot mutations; animating layout properties; uncontained animations; expensive filters over large regions.
- **Practices**: Simpler selectors, `contain` / `content-visibility`, compositor-friendly animations, scope expensive effects.

### 9. Loading states and CLS

- **Signals**: Images/embeds without reserved space; web fonts without metrics fallback; skeletons that resize when data loads; late third-party injectors.
- **Practices**: Explicit dimensions, `aspect-ratio`, min-height placeholders, font-display and metric fallbacks, third-party placeholders.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Main-thread work threatening INP/LCP budgets; layout thrash in hot paths; unbounded list mount; large CLS on primary content; full-tree rerender every keystroke without mitigation |
| **Medium** | Redundant renders at scale; heavy derive for medium lists; missing lazy/srcset; imports blocking tree-shake; layout-triggering animations |
| **Lower** | Marginal memos; theoretical issues without measurement; polish on already-acceptable UI |

## Using this knowledge

Quote hooks, imports, or CSS when reasoning. State assumptions (list length, device class). Mention **hydration** and **SSR** costs when relevant. Prefer removing redundant manual memo when the framework compiler handles it.
