# UI testing (end-to-end flow)

> **Hard rules — MUST be followed, never "just this once".**

Unit tests (`unit-testing.md`) prove the logic. UI tests prove the **screen works end to end** on a real app: real views, real DI, real API, real SwiftData. Write a UI test only for what a unit test cannot see: what is on screen, in what order, what a tap does, what VoiceOver reads.

## Setup
- Target `EverfitTestUITests`, folder `EverfitTestUITests/` (synchronized folder). XCTest + `XCUIApplication` (Swift Testing cannot drive UI yet).
- File layout: `<Screen>UITests.swift` (the tests) + `Support/<Screen>Screen.swift` (page object: element queries, waits, scrolling) + `Support/` helpers shared by screens. Tests never build queries by hand.
- **Launch arguments** (`Support/UITestLaunch.swift`), on every launch:
  - `-uiTesting` → `AppContainer` uses an **in-memory** SwiftData store: every launch starts with no cache and no toggles, so tests never depend on each other or on earlier runs.
  - `-AppleLanguages (en) -AppleLocale en_US` → fixed text; en_US starts weeks on Sunday, which also proves the app stays Monday-first.
- No mock data in the app (`CLAUDE.md`): UI tests run against the **real API**. Expected values come from the API at test time (the test fetches `GET /workouts` itself), never from copied JSON. Needs network.
- "Today" is the real date. Expected dates/relations are computed in the test with a Monday-first Gregorian calendar. A case that needs data the API does not give this week (e.g. no future workout on Sunday) calls `XCTSkip` with the reason — never a fake pass.

## Accessibility identifiers
- Every element a UI test touches has an identifier from `AppAccessibilityID` (`Core/Constants`), mirrored as plain strings in the UI test page object (the UI test target cannot import the app).
- Format `<screen>.<element>` (`calendar.dayDate`, `calendar.workout.<_id>`, `common.loading`). Workout cards use the API `_id`, so a test can find the card of a given API item.
- Query by identifier, assert on `label` / `value` (what VoiceOver reads) and traits (`.button` = tappable). Never query by visible text or index of a lazy list.
- State that is shown only by colour (e.g. today in purple) must also be exposed to VoiceOver (`accessibilityValue`), and the test asserts that value.

## What a screen's UI tests must cover
| # | Area | Must cover |
|---|---|---|
| 1 | Structure | every fixed part is there, in order (e.g. 7 days Mon→Sun of the current week, right day numbers) |
| 2 | Highlight / selection | the highlighted item is the right one and only one (today) |
| 3 | First load | dates/structure visible, loading indicator shown with no cache, gone after data arrives |
| 4 | Content vs API | every API item appears in the right place with the required fields (name, count…) and the full text is read by VoiceOver |
| 5 | Rules on screen | each display rule visible to the user (status per date: past missed/completed, today assigned/completed, future upcoming) |
| 6 | User action | tap applies the change on screen; second tap reverts it |
| 7 | Not allowed | elements a rule forbids are not tappable and do not change on tap |
| 8 | Refresh | pull-to-refresh keeps content and user changes |

Not UI-tested (say so in the feature file, cover by unit tests + manual check): pixel styling (colours, fonts, truncation "…" — check in `#Preview` and on the smallest simulator), error alerts and offline (needs a failing network; covered by ViewModel/repository unit tests), relaunch persistence (in-memory store; covered by repository tests).

## How to write
- One behaviour per test, named `test<Behaviour>` in plain English.
- Always wait (`waitForExistence`, `XCTNSPredicateExpectation`); never `sleep`. Default timeout 15 s (real network).
- Lazy lists: scroll (page object `scrollTo`) until the element exists; off-screen rows are not in the hierarchy.
- Each feature lists its UI cases in `features/<feature>.md` ("UI test coverage").

## Running
`xcodebuild test -project EverfitTest.xcodeproj -scheme EverfitTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EverfitTestUITests -parallel-testing-enabled NO` (run in background; slower than unit tests). The Stop hook runs only unit tests.
