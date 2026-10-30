# EverfitTest — Weekly Training Calendar

A SwiftUI app that shows the current week (Monday–Sunday) of a user's workouts, with per-day status and local mark/unmark. Data comes from `GET https://mock.internalef.com/workouts` and is cached offline-first in SwiftData.

**Demo video:** [Watch on Google Drive](https://drive.google.com/file/d/1Pc_s86ytfD0E0Rvq5QeHWglAd7jPR9ZX/view?usp=sharing)

**Source code:** [github.com/datanhle/everfitTest](https://github.com/datanhle/everfitTest)


| | |
|---|---|
| Platform | iOS 26.5, SwiftUI |
| Architecture | Clean Architecture (Presentation / Domain / Data) + MVVM |
| Concurrency | Swift Concurrency (async/await), default MainActor isolation |
| Networking | Alamofire 5 behind an app-owned `NetworkClient` |
| Persistence | SwiftData |
| Tests | 84 unit tests (Swift Testing) + 8 UI tests (XCUITest) |

## Features

- **Week view** — 7 day rows, Monday first; weekday on top, day of month below; today highlighted in purple.
- **Workout cards** — name truncated with "…", exercise count and status, styled per Figma:

  | Day | Status | Card |
  |---|---|---|
  | Past | Missed / Completed | Red "Missed" word / purple card |
  | Today | Assigned / Completed | Exercise count only / purple card |
  | Future | — | Greyed out, read-only |

- **Mark / unmark** — tapping a past or today's workout toggles it locally by `_id`; completed cards show a check mark. Toggles survive relaunches and re-fetches.
- **Loading state** — dates are visible immediately; workout data fills in when it arrives.
- **Offline-first** — on launch the last cached week shows instantly, then the API refreshes it. On failure the cached rows stay and an alert explains the error.
- **Accessibility** — VoiceOver reads title, status and exercise count for every card, including statuses with no visible label.

## Build & Run

**Requirements:** Xcode 26.5, an iOS 26.5 simulator. Alamofire resolves through Swift Package Manager on first open.

1. Open `EverfitTest.xcodeproj`.
2. Select the **EverfitTest** scheme and an iPhone simulator.
3. Run (⌘R).

**Tests**

```sh
xcodebuild test -project EverfitTest.xcodeproj -scheme EverfitTest \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:EverfitTestTests -parallel-testing-enabled NO
```

## Using the app

- **Open the app** — the current week (Monday–Sunday) is shown; today's date is purple.
- **First launch** — the dates appear at once with a "Loading…" indicator over them until the workouts arrive. Later launches show the last saved week immediately, then refresh it from the API.
- **Refresh** — pull the list down.
- **Mark / unmark** — tap a past or today's workout to mark it completed (purple card with a check mark); tap it again to unmark. Future workouts are greyed out and cannot be tapped. Your marks are kept after a refresh and after relaunching the app.
- **Offline or API error** — the last saved week stays on screen and an alert explains the error; tap **Close**, then pull to refresh to try again. On a first launch with no saved data, only the dates are shown.

## Architecture

```
Features (View → ViewModel) ──▶ Domain (Entities · Use cases · Repository protocols) ◀── Data (Repository · DTOs · SwiftData)
                         all layers may use Core: Networking · DesignSystem · Utilities
```

| Layer | Responsibility |
|---|---|
| **Domain** | Pure Swift (Foundation only). Every business rule: week dates (`WeekCalculator`), past/today/future (`DayRelation`), display status (`ScheduleStatus`), read-only future workouts, odd-API-data handling (`WeeklySchedule`). |
| **Data** | `DefaultWorkoutRepository` is the single source of truth: calls the API, caches the raw response, merges the user's toggles. All SwiftData access goes through the shared `SwiftDataStore` (fetch, replace single-row cache, upsert keyed records). DTOs and SwiftData models never leave this layer. |
| **Features** | `@Observable` ViewModel sequences use cases and maps entities to UI models. Views only render and forward taps. |
| **Core** | Networking (Alamofire is isolated here), design tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppIcons`, `AppStrings`), utilities. |
| **App / DI** | `AppContainer` is the one place objects are created: shared infrastructure once, then `makeCalendarViewModel()` wires Repository → Use cases → ViewModel. |

### Data flow

```
CalendarView .task / .refreshable
  └─ CalendarViewModel.load()
       ├─ ① first load only: cachedSchedule() → repository.cachedWeek()          SwiftData, shown immediately
       └─ ② fetchSchedule() → repository.fetchWeek() → GET /workouts → [DayDTO]
              → overwrite cache → merge local toggles → WeeklySchedule → UI models
              success: show · cancelled: ignore · error: alert, cached rows stay

WorkoutRow tap → toggleCompletion(id) → ToggleWorkoutCompletionUseCase → repository.setCompleted → updated schedule
```

### Key decisions

- **One data shape online and offline.** The API's `[DayDTO]` is stored as-is in SwiftData and mapped by the same `toDomain()`, so there is no second cache model to keep in sync.
- **Toggles are stored apart from the cache** (`CompletionRecord`), so a fetch never wipes them. The stored value is a `Bool`, so a workout the API reports as completed can still be unmarked.
- **A failed cache write never hides fresh data**; only `APIError` crosses layers.
- **Overlapping loads** (`.task` + pull-to-refresh): only the newest `load()` may update the screen.
- **Identical data is not re-applied**, so `@Observable` does not redraw the list.
- **No hard-coded UI values.** Colors, fonts, spacing, icons and strings come from tokens taken from Figma Dev Mode.

## Assumptions & Known Limitations

- API `day` index: **0 = Monday … 6 = Sunday**.
- API `status` (undocumented): **0 = assigned, 1 = missed, 2 = completed**; unknown values fall back to assigned.
- Displayed status comes from the date and completion, not directly from the API: a past workout that is not completed is missed; a future workout is always upcoming.
- Per Figma, today's assigned cards show only the exercise count, and completed cards show only "Completed". VoiceOver still reads the full status and count.
- Odd API data: plans for the same day are merged, a repeated workout `_id` keeps its first occurrence, and `day` outside 0–6 is ignored.
- **Limitation:** the API returns `day` 0–6 without dates, so a cache saved last week appears on this week's dates until a fetch succeeds.
- The PDF's mockable.io endpoint is no longer reachable; the app uses `mock.internalef.com`.

## Testing

| Layer | Tests | Coverage |
|---|---|---|
| Domain | 36 | Week dates, day relation, status rules, odd API data, `settingCompletion`, toggle and load use cases |
| Data | 21 | DTO mapping (user mark wins over API status); `SwiftDataStore` (fetch, replace, upsert, failed save); repository over in-memory SwiftData: cache read/write, unreadable cache, failed write, toggles across relaunch |
| Features | 20 | ViewModel: cache before network, errors keep rows and show an alert, cancellation, overlapping loads, toggles; presentation mapping |
| Core | 8 | `APIError` mapping; `HTTPNetworkClient` over a stubbed `URLProtocol` (status codes, decoding, cancellation) |

**UI tests** (`EverfitTestUITests`, real API + in-memory store via `-uiTesting`, en_US locale). Expected values are fetched from the API by the test and today's real date:
week Mon→Sun with this week's dates · only today marked "Today" · first load shows workouts and the indicator goes away · every API workout shows its full name and exercise count on its day · status follows the date (future cards not tappable) · tap marks / unmarks · future card is read-only · pull-to-refresh keeps toggles.

```sh
xcodebuild test -project EverfitTest.xcodeproj -scheme EverfitTest \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:EverfitTestUITests -parallel-testing-enabled NO
```

Checked by hand (not automatable without a fake network): colours/fonts and "…" truncation (previews, iPhone SE), error alert and offline, relaunch persistence (covered by repository unit tests).

## AI Collaboration

**Tools:** Claude Code (Claude Opus) in the terminal, with a project `CLAUDE.md` that encodes the architecture, layering and design-token rules so every generation follows the same conventions.

**How I worked:** requirements and data flow first; code only after I approved a plan; then the result was checked against the requirement, Figma and the test suite. Complex AI-generated logic is marked in code with `// Generated via Claude. Adjusted to handle <edge case>.` The full prompt log is in [`docs/ai-prompts.md`](docs/ai-prompts.md).

**Key prompts:**

1. **Requirements analysis before any code**
   > _"Analyze the requirements in Everfit_Mobile_Test Guide.pdf. Act as a Senior iOS Engineer. Before writing any code, give a structured analysis: functional requirements and edge cases; API, data models, persistence, caching and offline behavior; missing information, broken resources and risks; acceptance criteria with how to verify each one; and an implementation strategy. Separate explicit requirements from assumptions. Do not invent requirements or make architectural decisions for me. Do not generate code or modify files. End with the decisions that need my approval."_

2. **Base project — plan and data flow before code**
   > _"First, I need to decide on the architecture. I need to create a base project with SwiftUI + MVVM + Repository + async/await. Project structure (App/Core/Features/Data/Resources/EverfitTests). I also need Core/DesignSystem/AppTypography and Core/Constants/Colors as shared code. Do not hard-code values in UI; fix once for all. 
   > _"Let's plan and show an example of the data flow before writing code."_

3. **UI — analyze the design, then render it**
   > _[Figma "training" and "training - empty" frames] "This is the Figma screen for the Calendar. First, let's analyze all components of this screen."_
   > _"Compare the UI with the current code. I need to convert the design into pixel-perfect UI."_Let's ask me everythink you need to do make sure enough information to do.

4. **Test audit before adding tests**
   > _"Audit every test in EverfitTests/ against the code in EverfitTest/. Do not edit any file yet. For each rule or function with logic, return a table: case · existing test · does it really check the logic · what's missing."_ — followed by a checklist of date, status, toggle, cache, ViewModel, network and odd-API-data cases follow rule.

   → I chose which gaps to fix from the table. Two were real bugs (overlapping loads, odd API data); tests went from 51 to 64.

Every AI output was reviewed against `CLAUDE.md` and verified by the test suite before being kept.

## Bonus: End-to-End Feature Workflow

How I take a feature from request to release:

1. **Analyze before coding** — read the requirement and design, then turn them into a checklist: rules, edge cases, open questions and acceptance criteria, each with how it will be verified. Confirm assumptions with product/design before writing code.
2. **Design** — sketch the data flow and which layer each piece belongs to; agree on the API contract; split the work into small, reviewable steps.
3. **Build, layer by layer**
   - **Domain** — entity, repository protocol, use case and its rules, with unit tests (stub repository, fixed clock).
   - **Data** — DTO, `APIRequest`, mapper, repository implementation, with tests over in-memory storage and a stub network client.
   - **Features** — UI models, presentation mapper, ViewModel, Views using design tokens only, each with a `#Preview`.
   - **App / DI** — add a `make<Screen>ViewModel()` to `AppContainer`; add a coordinator once navigation is involved.
4. **Verify** — go through the checklist from step 1 item by item: unit tests, run against the design (offline, slow network)
5. **Testing** — Manual Testing and fix bugs
6. **Review** - Create PR with taskID and add evidences.
6. **Relase** Release version to TF.
