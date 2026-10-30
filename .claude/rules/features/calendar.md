---
paths:
  - "EverfitTest/Features/Calendar/**"
  - "EverfitTest/Domain/**"
  - "EverfitTest/Data/**"
  - "EverfitTests/**"
---

# Feature: Calendar (weekly workouts) — reference implementation

Feature-specific facts for the Calendar screen. Generic rules are in `architecture.md`, `swift-code.md`, `design-system.md`, `unit-testing.md`; this file shows how they were applied — copy its shape for a new `features/<feature>.md`.

## Units
| Layer | Units |
|---|---|
| Features | `CalendarView`, `DayCell`, `WorkoutRow` (+ shared `LoadingIndicator`) · `CalendarViewModel` · `DayItem`, `WorkoutItem` · `CalendarPresentationMapper`, `ScheduleStatus+Style` |
| Domain | `LoadWeeklyScheduleUseCase`, `ToggleWorkoutCompletionUseCase` · `WeeklySchedule`, `ScheduledDay`, `ScheduledWorkout`, `ScheduleStatus`, `DayRelation`, `Workout`, `WorkoutStatus`, `DayPlan` · `WeekCalculator` · `WorkoutRepository` |
| Data | `DefaultWorkoutRepository` · `WorkoutsRequest`, `DayDTO`, `AssignmentDTO`, `WorkoutDTOMapper` · `CachedResponse`, `CompletionRecord` (via shared `SwiftDataStore`) |
| DI | `AppContainer.makeCalendarViewModel()` |

## Read flow (offline-first, `GET /workouts`)
```
CalendarView .task / .refreshable ─▶ CalendarViewModel.load()
 ├─ ① first load only: useCase.cachedSchedule() ─▶ repository.cachedWeek()   (SwiftData, sync) ─▶ show
 └─ ② await useCase.fetchSchedule() ─▶ repository.fetchWeek()
        └─ networkClient.send(WorkoutsRequest()) ─▶ overwrite CachedResponse ─▶ [DayDTO].toDomain()
     success → show · .cancelled → ignore · other APIError → alert, cached rows stay
```
- `CachedResponse.payload` = the API's `[DayDTO]` as JSON (one row). Empty `data: []` is cached as an empty week (`cachedWeek() == []`, not `nil`).
- `LoadWeeklyScheduleUseCase`: `emptyWeek()` (7 dated days while loading), `cachedSchedule()`, `fetchSchedule()`; all build `WeeklySchedule` the same way (`WeekCalculator` + `DateProvider`).
- `CalendarViewModel`: cache only while nothing is shown; `isLoading` until the first data (drives `LoadingIndicator`); identical data causes no redraw (`@Observable` skips equal values); overlapping loads guarded by `loadCount`; errors → `errorMessage` → `.alert` (`isShowingError` clears it).
- Odd API data, handled in `WeeklySchedule.init`: same `day` twice → merged in API order; repeated workout `_id` → first (earliest day) kept; `day` outside 0–6 → ignored; unknown `status` → assigned.
- Display status comes from the date + completion only (`ScheduleStatus`): past → missed/completed, today → assigned/completed, future → upcoming. API status 1 (missed) shows as assigned today / upcoming in the future.
- Known limitation (accepted): API `day` is 0–6 without dates, so last week's cache shows on this week's dates until a fetch succeeds.

## Write flow (mark / unmark a workout)
- `WorkoutRow` tap → `DayCell.onTapWorkout(id)` → `CalendarViewModel.toggleCompletion(workoutID:)` → `ToggleWorkoutCompletionUseCase.execute(workoutID:in:)` (flip, `repository.setCompleted`, return `schedule.settingCompletion`) → `apply`.
- `ScheduledWorkout.status` is computed (`relation` + `isCompleted`); `settingCompletion` copies `self` and flips one `isCompleted`.
- Toggles are stored in `CompletionRecord { workoutID, isCompleted }`, apart from `CachedResponse`; the repository merges them via `DayDTO.toDomain(userCompletions:)`. Domain only has `Workout.isCompleted`.
- Future workouts are read-only: `canToggleCompletion` false for `.upcoming` → use case ignores → `WorkoutItem.canToggle` → `WorkoutRow` renders a plain card (no `Button`, no hint).

## Design (Figma node `23776-49540`, frames "training" / "training - empty")
- No screen title; full-width day rows with a bottom divider, min height 112 (`AppSpacing.Calendar`).
- Date column: weekday uppercase grey, day number dark; today = purple weekday + day.
- Card subtitle: missed "Missed • N exercises" (red word); today "N exercises" (no "Assigned" word); completed = purple card + "Completed" only + check-mark badge; future "N exercises" grey.
- VoiceOver always reads title, status and count. First load without cache = dates + shared `LoadingIndicator` as an overlay centered on the list; reload = pull-to-refresh only; empty = dates only.
- Still screenshot estimates (no Figma spec yet): `screenBackground`, `divider`, `rowMinHeight`, card radius, badge size.

## Test doubles for this feature
- `StubWorkoutRepository(cached:, result)` — sync cache + one fetch result; `onFetch` runs mid-fetch; `savedCompletions` records toggles.
- `GatedWorkoutRepository` — holds each fetch until `finishFetch(i, with:)`, in any order.
- `Fixtures.response()` / `.response(day:workoutIDs:)` / `.workout(id:isCompleted:)`.

## Test coverage registry
What the generic templates in `unit-testing.md` produced for this feature. Keep it up to date: when a unit is added or changed, update its row.
`View → CalendarViewModel → UseCase → WeeklySchedule / WeekCalculator / DayRelation / ScheduleStatus → Repository → NetworkClient + SwiftData`

**Domain** — pure, no I/O (`FixedDateProvider`, `StubWorkoutRepository`)
| Unit | Must cover |
|---|---|
| `WeekCalculator` | midweek → Mon…Sun; input on Monday; input on Sunday stays in the week that started the previous Monday; week across month/year end; DST week → 7 distinct start-of-day dates |
| `DayRelation` | past / today / future; time of day ignored (23:59 yesterday = past, 00:01 today = today) |
| `ScheduleStatus` | full matrix: past/today/future × completed true/false (future is always `.upcoming`) |
| `WeeklySchedule.init` | empty plans → 7 dated empty days; plan placed on its weekday; same weekday twice merged in API order; repeated ID keeps first (earliest day); weekday outside 0–6 ignored; API "missed" shown by date (today → assigned, future → upcoming) |
| `WeeklySchedule.settingCompletion` | mark/unmark past (completed↔missed) and today (completed↔assigned); future stays upcoming; only that workout changes; original value unchanged; unknown ID → equal copy |
| `LoadWeeklyScheduleUseCase` | `emptyWeek` = 7 dated days; `cachedSchedule` nil without cache / built from cache; `fetchSchedule` builds the week; repository error forwarded unchanged |
| `LoadWeeklyScheduleUseCase` (extra) | cached `[]` → 7 empty days (not nil); empty response → 7 empty days; fetch ignores cache; today = Monday 00:00 / Sunday 23:00 → same Mon–Sun week, one today; every `APIError` forwarded unchanged |
| `ToggleWorkoutCompletionUseCase` | marks / unmarks and saves the new value; mark today (assigned → completed); unmark past (completed → missed); second tap restores original, last value saved; original schedule untouched; future (even API-completed) ignored and nothing saved; tap before data / unknown ID → same schedule, nothing saved; only the tapped workout changes |

**Data** — real repository, in-memory SwiftData + `StubNetworkClient`; share one `ModelContainer` between repositories to simulate a relaunch
| Unit | Must cover |
|---|---|
| DTO decoding + `WorkoutDTOMapper` | real JSON shape (`_id`, `total_exercise`, `day`, `status`); status 0/1/2; unknown status → not completed; `userCompletion` wins both ways (unmark API-completed, mark API-missed) |
| `SwiftDataStore` | empty store → no rows; fetch/first filter by predicate; `replaceAll` keeps one row; `upsert` inserts then updates without duplicating; failed save throws |
| `DefaultWorkoutRepository` cache | `cachedWeek` nil before first fetch; fetch returns fresh data and saves it; next launch reads it; newer fetch replaces cache; fetch error throws and keeps cache; unreadable cache → nil, then replaced; failed cache write still returns fresh data; `data: []` cached as `[]` (not nil) |
| `DefaultWorkoutRepository` toggles | saved toggle merged into cached and fetched weeks; survives a fetch that overwrites the cache; survives relaunch offline; can unmark API-completed; last toggle wins |

**Features** — real use cases over `StubWorkoutRepository` / `GatedWorkoutRepository`
| Unit | Must cover |
|---|---|
| `CalendarPresentationMapper` + `ScheduleStatus+Style` | weekday text Monday-first, uppercased, locale-based; day number; `isToday`; workout fields + exercise-count text; `canToggle`; labels per Figma (assigned/upcoming none, missed, completed only) |
| `CalendarViewModel.load` | before load: 7 dated days, `isLoading`; cache shown before network (`onFetch`), not loading; fresh replaces cache; refresh does not re-read cache; identical data does not notify observers; error → alert message, rows kept, `isLoading` false; error without cache; `.cancelled` → no alert, rows kept; closing alert clears message; empty response → 7 empty days |
| Overlapping loads | older load finishing last does not overwrite newer data; older load failing last shows no error; `isLoading` stays until the newest load finishes |
| `CalendarViewModel.toggleCompletion` | mark → completed + saved; second tap unmarks; future not tappable; tap before data does nothing |

**Core** — networking
| Unit | Must cover |
|---|---|
| `APIError` | `URLError` codes → noInternet / timeout / cancelled / unknown; 401 → unauthorized; non-2xx reads `message` from body; unreadable body → generic message; `userMessage` per case |
| `HTTPNetworkClient` (stub `URLProtocol`, `retryLimit: 0`) | success decodes + URL, method, default headers; non-2xx → `.server` with message; bad body → `.decoding`; cancelling the Task cancels the request → `.cancelled` |

## UI test coverage (`EverfitTestUITests/CalendarUITests.swift`, rules in `ui-testing.md`)
| # | Test | Checks |
|---|---|---|
| 1 | `testWeekShowsSevenDaysMondayToSunday` | 7 date labels MON…SUN with this week's day numbers (en_US, Sunday-first locale) |
| 2 | `testOnlyTodayIsMarkedToday` | exactly one date has value "Today", on today's weekday |
| 3 | `testFirstLaunchShowsLoadingThenWorkouts` | no cache → loading indicator, then cards, indicator gone |
| 4 | `testEveryAPIWorkoutShowsNameAndExerciseCountOnItsDay` | each API `_id` card: full title, "N exercise(s)", under its weekday |
| 5 | `testStatusFollowsTheDate` | past missed/completed, today assigned/completed, future upcoming and not a button |
| 6 | `testTapMarksAndUnmarksWorkout` | tap → Completed; tap again → original status |
| 7 | `testFutureWorkoutIsReadOnly` | future card is not a button; tap changes nothing |
| 8 | `testPullToRefreshKeepsWorkoutsAndToggles` | toggle, pull to refresh, still Completed |
Manual only: colours/fonts/truncation (preview + iPhone SE), error alert and offline, relaunch persistence.

