# EverfitTest — Claude rules

iOS hiring test: weekly training calendar (Mon–Sun). Clean Architecture (Presentation / Domain / Data) + MVVM in Presentation + async/await. Offline-first data with a SwiftData cache.
Xcode 26.5, iOS 26.5 target, Swift 5 mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency ON.

## Project setup
- Xcode 26 **synchronized folders**: any file placed under `EverfitTest/` or `EverfitTests/` is auto-added to its target (fonts included). Never edit `project.pbxproj` to add files.
- Test target is named `EverfitTestTests` but its folder is `EverfitTests/`. Tests use Swift Testing (`import Testing`, `@Test`, `#expect`).
- API: `https://mock.internalef.com/workouts`. The `mockable.io` URL in the PDF is dead — do not use it.
- SwiftData access goes through `Data/Local/SwiftDataStore`, which must hold the `ModelContainer` itself: a `ModelContext` does not retain its container, and the app crashes on launch (test runner "crashed before establishing connection") if only the context is kept.
- **No bundled mock data.** Offline data comes only from the SwiftData cache. Do not add JSON fixtures to the app bundle.

## Rules — read before planning or writing code
**New screen / feature:** follow `architecture.md` (golden rules + flow patterns) and the procedure in `unit-testing.md`, create `features/<feature>.md` modeled on `features/calendar.md`, and present the plan (files per layer, flow, test case table) before writing code.

Project rules live in `.claude/rules/` (loaded by Claude Code; path-scoped ones load when a matching file is read or edited — read the relevant file yourself when planning). They are hard rules, not suggestions.

| File | Covers |
|---|---|
| `.claude/rules/architecture.md` | golden rules, folder structure, layer rules, DI, read/write flow patterns (always loaded) |
| `.claude/rules/swift-code.md` | adding an endpoint, concurrency, safety, naming, readable-code style |
| `.claude/rules/design-system.md` | tokens, building a screen from Figma, states, accessibility, typography |
| `.claude/rules/unit-testing.md` | procedure for a new feature, 7 case categories, cases by component type, how to write and run tests |
| `.claude/rules/ui-testing.md` | end-to-end UI tests: launch arguments, accessibility identifiers, what a screen must cover, how to run |
| `.claude/rules/ai-logic-marker.md` | `// Generated via Claude. Adjusted to handle edge case: <X>.` |
| `.claude/rules/features/<feature>.md` | facts of one feature: flows, design, test doubles, coverage table. `features/calendar.md` is the reference to copy for a new feature |

Enforcement (`.claude/settings.json`, scripts in `.claude/hooks/`):
- `check-swift-rules.sh` (PostToolUse on Edit/Write of `EverfitTest/**/*.swift`): layer imports, async/await only, no `Date()`/`try!`/`as!`, no hard-coded UI values in Views, logic files must have tests. Exit 2 → fix immediately.
- `run-tests-on-stop.sh` (Stop): runs the unit tests when any Swift file changed since the last green run; failing tests block the end of the turn.
- When a rule changes, update the rule file **and** the hook script together. Never weaken or bypass a hook to make a change pass.

## Deliverables (keep in mind)
README must contain: build steps, assumptions (status 0/1/2 mapping, day 0 = Monday, "Assigned" word omitted per Figma (status still conveyed by today's purple date + VoiceOver) and completed cards show only "Completed" (count still read by VoiceOver), last-week cache limitation), "AI Collaboration" section (tools + 2–3 real prompts), video link, bonus end-to-end feature workflow.
