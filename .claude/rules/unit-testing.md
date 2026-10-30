---
paths:
  - "EverfitTest/**/*.swift"
  - "EverfitTests/**/*.swift"
---

# Unit testing

> **Hard rules — MUST be followed, never "just this once".** Items marked 🔒 are enforced by hooks; a violation is sent back and must be fixed before continuing.

🔒 Enforced: a logic file in `Domain/`, `Data/`, `Core/Networking/`, `Features/*/ViewModels|Mappers/` must be referenced by at least one test (`check-swift-rules.sh`) · a turn cannot end while the suite fails (`run-tests-on-stop.sh`).

Every change that adds or alters logic ships with its unit tests **in the same change**, and the full suite must pass. These rules apply to any screen or feature: derive the cases from each unit's **component type**, following the procedure below. Each feature keeps its own coverage table in `.claude/rules/features/<feature>.md` (see `features/calendar.md` for a complete example).

## Procedure for a new screen or feature
1. **List the units in the flow**, top to bottom: `View → ViewModel → UseCase(s) → Domain entities/services → Repository → NetworkClient / SwiftData`. Views, design tokens and `AppContainer` wiring are not unit-tested.
2. **Give each unit its component type** from "Test cases by component type" (a unit with several roles uses every matching template).
3. **Write the case list before any test code**: a table `Unit | Case | Category (1–7) | Test name`, built from the templates + the 7 required categories. Present it in the plan for approval.
4. **Create test doubles in `EverfitTests/Support/`** for every new protocol: `Stub<X>` (fixed `Result`, records calls and arguments, optional `on<Call>` closure to observe state mid-call); `Gated<X>` when calls can overlap (holds each call until the test finishes it, in any order).
5. **Write the tests**, one file per unit, run the full suite, then add/update the feature's coverage table in `features/<feature>.md` and the README test counts.

UI tests (what is on screen, taps, VoiceOver) follow `ui-testing.md`.

## Required case categories (every unit with logic, where they apply)
1. **Happy path** — normal input, expected output.
2. **Errors** — each error that changes behaviour, separately: `.cancelled` (silent) vs other `APIError`s (shown); with and without cached/local data.
3. **Empty input** — empty list/response, no cache yet, no local state.
4. **Boundaries** — first/last element, start/end of a period (day, week, month, year), midnight, DST / time-zone change, min/max values.
5. **Odd API data** — duplicated keys or IDs, out-of-range values, unknown enum raw values, missing optional fields, unexpected body.
6. **State kept on failure** — current data stays, original value unchanged, nothing saved.
7. **Ignored actions** — not allowed by a rule, unknown ID, action before data is loaded, stale (older) async result → no change and no side effect.

## Test cases by component type
Every template below is in addition to the 7 required categories. "Each" means one test per value, or one `@Test(arguments:)`.

| Component type | Test with | Must cover |
|---|---|---|
| **Domain rule / enum with logic** (e.g. a status rule) | direct values | each input combination → output (full truth table); every enum case reached; defaults for unknown input |
| **Domain service — calculation** (dates, money, sorting) | `FixedDateProvider`, `TestCalendar` | typical input; first/last element of a range; period boundaries (start/end of day, week, month, year); DST / time-zone change; empty and invalid input; output order and count |
| **Domain entity that builds or normalizes data** (init from raw plans, merge, group) | direct values | empty input → valid empty result; each item placed correctly; duplicates (same key twice, same ID twice); out-of-range / invalid values ignored; ordering kept; derived properties correct |
| **Domain entity — copy-and-modify** (`setting…`, `with…`) | direct values | the target changes; derived values follow; nothing else changes; original value untouched; unknown target → equal copy |
| **Use case — read** | `Stub<X>Repository` | result built from repository data; empty repository data; no cache vs cache; each repository error forwarded unchanged (and `.cancelled` stays `.cancelled`) |
| **Use case — write / user action** | `Stub<X>Repository` (records calls) | action applied and saved with the exact value; reverse action; each guard (not allowed, unknown ID, wrong state) → no change **and nothing saved**; only the target changes |
| **DTO + mapper** | JSON fixture in `Fixtures` | decode the real API shape (exact keys, nesting, optional fields missing/null); each enum raw value; unknown raw value → documented default; every field mapped; local override vs API value (both directions) |
| **Repository implementation** | real repo + in-memory SwiftData + `StubNetworkClient`; share one `ModelContainer` to simulate relaunch | remote success → mapped result + saved; read after relaunch; newer success replaces old data; each remote error → strategy (throw / keep cache); empty local store; unreadable/old-format local data; failed local write does not hide remote data; empty remote response; user-created local state merged, survives refresh and relaunch, last write wins |
| **Presentation mapper / style** | direct values, fixed locale | every UI field formatted (text, numbers, dates, locale, case); flags (`isToday`, `canX`); each status → label/colour/visibility per design; empty collections |
| **ViewModel — load** | real use cases over `Stub<X>Repository` (`onFetch` to inspect mid-load), `Gated<X>Repository` for overlap | initial state before load; loading flag during first load and not on reload; cached data shown before network; success replaces data; refresh path; identical data does not notify observers; each error kind → message (or silent for `.cancelled`); data kept on error; closing the alert clears it; overlapping/older loads cannot overwrite newer state |
| **ViewModel — user intent** (tap, toggle, delete…) | same | happy path updates state and calls the repository; repeat/undo; guarded input (not allowed, unknown ID, before data) → no change, no call |
| **Networking** (`NetworkClient`, `APIError`) | stub `URLProtocol`, `retryLimit: 0` | success decode + URL, method, headers, body; each HTTP status class (2xx, 401, 4xx, 5xx) → error with server message; unreadable body; decoding error; `URLError` codes; cancellation → `.cancelled` |

**A new kind of component** not in this table → add a row here first (in the same change), then write its tests.

## How to write a test
- Swift Testing only (`import Testing`, `@Test`, `#expect`, `#require`). One suite per type, file mirrors the source: `EverfitTests/<Layer>/<Feature?>/<Type>Tests.swift`. Suites touching app types are `@MainActor` (the test target is NOT MainActor by default).
- Name = the behaviour in plain English (`failedFetchKeepsCachedDataAndShowsError`), not `testLoad2`.
- One behaviour per test; Arrange / Act / Assert separated by a blank line. Table-like inputs → `@Test(arguments:)`.
- Fixed time only: `FixedDateProvider` + `TestCalendar` (UTC, Monday-first); the shared "today" is **Thu 2026-10-29** (week Mon 26 … Sun 1 Nov). Never `Date()`.
- No real network, no real disk: `StubNetworkClient` / `StubURLProtocol`, in-memory SwiftData (`SwiftDataStack.makeContainer(inMemory: true)`). Exception: simulating a failed local write (store reopened from disk with `allowsSave: false`; in-memory + `allowsSave: false` fails to load).
- Use the real implementation one level below the unit under test where it has no I/O (ViewModel tests use the real use cases over a stub repository; repository tests use real SwiftData in memory).
- Assert results (return values, ViewModel state) and side effects through doubles (recorded calls). Never assert private details.
- Errors are typed: `await #expect(throws: APIError.noInternet) { … }`. Check both the error and what is kept.
- Test doubles and fixtures live only in `EverfitTests/Support/` (`TestDoubles.swift`, `FixedDateProvider.swift`); reuse them, add new ones there, never copy one into a test file. JSON fixtures mirror the real API shape.
- Bug fix → first a failing test that reproduces it, then the fix.
- Only types with no logic (stored properties only, protocol declarations, constants) may be added to the hook's `exempt` list in `check-swift-rules.sh`, with the reason; never exempt a type that has logic.

## Running
- Command: `xcodebuild test -project EverfitTest.xcodeproj -scheme EverfitTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EverfitTestTests -parallel-testing-enabled NO` (~1–2 min; run in background). Counts: `xcrun xcresulttool get test-results summary --path <latest .xcresult in DerivedData/EverfitTest-*/Logs/Test>`.
- Update the test counts in README (header + Testing table) when they change.
- `StubURLProtocol.delay` keeps a request in flight so a test can cancel its Task. URLProtocol stubs must send `Content-Type: application/json` (`.validate()` checks it).
- Parallel mode clones simulators (~8 min). "Failed to create a bundle instance ... EverfitTestTests.xctest" is a simulator install flake — rerun once.
- After killing `xcodebuild`, the simulator may fail with "(ipc/mig) server died" — reboot it (`xcrun simctl shutdown/boot "iPhone 17"`), don't wait on `bootstatus -b`.
- SourceKit shows false "Cannot find X in scope" / "No such module 'Testing'" right after files are added — ignore; trust `xcodebuild`.
