import Foundation
import Observation

/// Coordinates use cases and exposes UI state. No business rules live here.
@Observable
final class CalendarViewModel {
    private(set) var days: [DayItem] = []
    /// True until any data (cache or network) is shown; day cells still show their dates.
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    /// Drives the error alert; closing it clears the message.
    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    private let loadScheduleUseCase: LoadWeeklyScheduleUseCase
    private let toggleCompletionUseCase: ToggleWorkoutCompletionUseCase
    /// What `days` currently shows; `nil` until cache or network data arrives.
    private var schedule: WeeklySchedule?
    /// Increments on every `load()`; only the newest load may update the screen.
    private var loadCount = 0

    init(loadSchedule: LoadWeeklyScheduleUseCase, toggleCompletion: ToggleWorkoutCompletionUseCase) {
        loadScheduleUseCase = loadSchedule
        toggleCompletionUseCase = toggleCompletion
        // Runs before the first frame, so the screen never starts blank; `load()` later fills in the workouts.
        // Output: 7 DayItems MON 26 … SUN 1, each with `workouts: []`
        days = CalendarPresentationMapper.map(loadScheduleUseCase.emptyWeek())
    }

    /// Offline-first: show the SwiftData cache right away, then replace it with the API's fresh week.
    func load() async {
        loadCount += 1
        let thisLoad = loadCount
        errorMessage = nil
        // Cache only on the first load; on refresh the screen already shows the latest data.
        if schedule == nil, let cached = loadScheduleUseCase.cachedSchedule() {
            apply(cached)
        }
        isLoading = schedule == nil
        // Generated via Claude. Adjusted to handle edge case: overlapping loads (.task + pull-to-refresh); a stale load changes nothing.
        do {
            let fresh = try await loadScheduleUseCase.fetchSchedule()
            // A newer load started while this one was waiting; let the newer one update the screen.
            guard thisLoad == loadCount else { return }
            apply(fresh)
        } catch {
            guard thisLoad == loadCount else { return }
            // `.cancelled` means the view went away: nothing to tell the user.
            // Any other error shows the alert; cached rows (if any) stay on screen.
            if error != .cancelled {
                errorMessage = error.userMessage
            }
        }
        isLoading = false
    }

    /// Mark/unmark a workout locally. Ignored until data is shown (there is nothing to tap before that).
    func toggleCompletion(workoutID: String) {
        guard let schedule else { return }
        apply(toggleCompletionUseCase.execute(workoutID: workoutID, in: schedule))
    }

    /// No equality check needed: `@Observable` does not notify when an `Equatable` property is set to an
    /// equal value, so a fetch that returns the data already on screen does not redraw the list.
    private func apply(_ schedule: WeeklySchedule) {
        self.schedule = schedule
        days = CalendarPresentationMapper.map(schedule)
    }
}
