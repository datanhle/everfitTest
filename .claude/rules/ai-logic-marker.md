---
paths:
  - "EverfitTest/**/*.swift"
---

# AI-generated logic marker

> **Hard rules — MUST be followed, never "just this once".**

Requirement from the test PDF: *"If AI generated a complex piece of logic (like date math for the calendar view), leave a brief comment in your code: `// Generated via ChatGPT. Adjusted to handle edge case X.`"*

- **Every time** you write or rewrite complex logic, in any feature, add the marker yourself in the same edit — do not wait to be asked.
- Format, exactly one line, first line inside the function body (or right above the expression):
  `// Generated via Claude. Adjusted to handle edge case: <X>.`
  Use "Claude" (the tool actually used); "ChatGPT" in the PDF is only the example tool name.
- `<X>` names the concrete edge case(s) the code handles, short and specific, e.g. `Sunday stays in the Monday-started week; DST days (adds calendar days, not 24h).`

## What counts as complex
| Marker needed | No marker |
|---|---|
| date / time / week / time-zone math | plain DTO → Entity field mapping |
| status or permission rules with several branches | property forwarding, computed one-liners |
| merging, grouping, deduplicating or normalizing API data | view layout and styling |
| combining cache, remote and user-created local state | DI wiring, factories |
| concurrency guards (overlapping loads, cancellation) | simple guards and early returns |
| index shifts / offsets (e.g. locale weekday symbols) | token/constant definitions |
| copy-and-modify of nested values | |

- Editing code that already has a marker: update its edge-case text if the handled cases change; never add a second marker.
- Explanation comments stay separate from the marker: `// <what this line does>` then `// Output: <result for the doc-comment example>` above the code line, with the example input given once in the `///` doc comment.
