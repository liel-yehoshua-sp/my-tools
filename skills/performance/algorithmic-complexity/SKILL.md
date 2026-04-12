---

## name: algorithmic-complexity

description: Detect algorithmic complexity issues, O(n²) bottlenecks, and performance risks. Use when reviewing code changes, examining implementation plans, or when the user asks for a performance review related to complexity and algorithms.

# Algorithmic Complexity Reviewer

This skill serves as a reference for detecting performance issues related to Algorithmic Complexity.

## Input Modes

The user will provide code or an implementation plan, along with one of two modes:

- **"review plan"**: Evaluate algorithmic risks in the proposed approach and suggest alternatives.
- **"review changes"**: Point to specific lines or patterns in the provided code with concrete fixes.

## Issues to Detect

Analyze the input and identify the following issues:

- **Unnecessary O(n²) or worse loops**: Nested iterations over the same or related collections where an O(n) or O(n log n) solution exists.
- **Redundant repeated iterations**: Iterating over the same collection multiple times when the logic could be merged into a single pass.
- **Wrong data structure choice**: For example, using an array/list for lookups (O(n)) where a set or hash map would provide O(1) lookups.
- **Unnecessary or repeated sorting**: Sorting data when it's not required for the logic, or sorting inside loops instead of once outside.
- **Missing early exits / short-circuits**: Continuing to iterate or process after the required condition or answer has already been found.
- **Exponential recursive blowup**: Recursive solutions that solve overlapping subproblems without memoization or dynamic programming.

## Output Format

Output each finding clearly, adhering to the following structure:

- **Severity**: [Critical / Warning / Info]
- **Location**: Specific lines for "review changes" mode, or the relevant architectural component for "review plan" mode.
- **Issue**: A clear description of the algorithmic complexity problem and why it degrades performance.
- **Suggested Fix**: A concrete alternative implementation, algorithm, or data structure.

### Example Output

- **Severity**: Warning
- **Location**: Lines 45-52 (or "User processing module")
- **Issue**: O(n²) loop due to `list.Contains()` inside a `foreach` loop. Lookups in a list take O(n) time, making the overall complexity O(n*m).
- **Suggested Fix**: Convert `list` to a `HashSet` (or equivalent map/set) before the loop to achieve O(1) lookups and O(n) overall complexity.