---
name: algorithmic-complexity
description: >-
  Algorithmic complexity knowledge: quadratic or worse loops, redundant passes,
  data structure choice, unnecessary sorting, missing short-circuits, and
  exponential recursion without memoization. Use when choosing algorithms,
  refactoring hot paths, estimating scale limits, or explaining why runtime
  grows with input size.
---

# Algorithmic complexity

Reference for **asymptotic behavior and common accidental regressions**.

## Core ideas

- **Count nested dependence**: if an inner operation scales with input, multiply complexities honestly (e.g. `Contains` in a loop over another collection).
- **Right structure for the operation**: lookups, order-statistics, and range queries have different best choices (hash map, tree, prefix sums, etc.).
- **Sort once, or not at all**: repeated sorting inside loops is a frequent smell.

## Patterns to recognize

### Unnecessary O(n²) or worse

- **Signals**: Nested iterations over the same or related collections where O(n) or O(n log n) exists (hash map/set, two-pointer, monotonic stack, etc.).
- **Practices**: Restructure to single pass, index one collection first, or use appropriate auxiliary structure.

### Redundant passes

- **Signals**: Multiple full scans when one merged pass can compute all needed aggregates.
- **Practices**: Combine conditions and accumulators in a single iteration when dependencies allow.

### Wrong data structure

- **Signals**: Array/list membership checks in hot inner loops; frequent middle deletes on arrays; priority needed but using unsorted scan.
- **Practices**: `HashSet`/map for membership O(1); deque/linked structure when middle edit patterns matter; heap when you need repeated min/max of a dynamic set.

### Unnecessary or misplaced sorting

- **Signals**: Sorting when only min/max or top-k needed; sorting inside a loop instead of once outside.
- **Practices**: Linear selection or heap for top-k; sort once after all mutations; partial sort only if API supports it cheaply.

### Missing early exit

- **Signals**: Continuing full scan after answer is known; processing all elements when boolean short-circuit suffices.
- **Practices**: Break/return as soon as predicate satisfied; branch reorder for cheap checks first.

### Exponential recursion without memoization

- **Signals**: Overlapping subproblems in naive recursion (Fibonacci-style, partition problems).
- **Practices**: DP table, memoization, or iterative bottom-up; prove subproblem count is bounded.

## Risk prioritization

| Level | Examples |
|-------|----------|
| **High** | Hot path with O(n²) or worse at production n; exponential recursion on user-sized input |
| **Medium** | Clear linearithmic upgrade available; repeated sorts/passes on large collections |
| **Lower** | Small-n domains where constants dominate; theoretical improvements without practical impact |

## Using this knowledge

State **n** (and multiple dimensions if several inputs). Give **concrete** structure changes (e.g. “build `HashSet` once, then single pass”). When parallelizing or distributing, complexity across machines still follows the algorithm unless work is perfectly partitioned.
