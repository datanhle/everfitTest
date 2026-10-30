import Foundation

protocol LoadWeeklyScheduleUseCase {
    /// The current week with no workouts — lets the UI show dates while loading.
    func emptyWeek() -> WeeklySchedule
    /// The week saved locally by the last successful fetch; `nil` when nothing is cached yet.
    func cachedSchedule() -> WeeklySchedule?
    /// The fresh week from the API (also refreshes the local cache).
    func fetchSchedule() async throws(APIError) -> WeeklySchedule
}

final class DefaultLoadWeeklyScheduleUseCase: LoadWeeklyScheduleUseCase {
    private let repository: WorkoutRepository
    private let dateProvider: DateProvider

    init(repository: WorkoutRepository, dateProvider: DateProvider) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    func emptyWeek() -> WeeklySchedule {
        // No plans yet: the 7 dates come from "today", not from the API.
        // Output: 7 days Mon 26 … Sun 1 Nov, each with `workouts: []`
        makeSchedule(plans: [])
    }

    func cachedSchedule() -> WeeklySchedule? {
        // No cache before the first successful fetch.
        guard let cachedPlans = repository.cachedWeek() else { return nil }
        return makeSchedule(plans: cachedPlans)
    }

    func fetchSchedule() async throws(APIError) -> WeeklySchedule {
        makeSchedule(plans: try await repository.fetchWeek())
    }

    /// Builds the week around "today" and places `plans` on their days.
    ///
    /// Example: today = Thu 29 Oct 2026.
    private func makeSchedule(plans: [DayPlan]) -> WeeklySchedule {
        // Current date from the injected clock (real clock in the app, fixed date in tests).
        // Output: Thu 29 Oct 2026
        let today = dateProvider.now

        // Calendar used for every date calculation.
        // Output: Gregorian, user's time zone, week starts on Monday
        let calendar = dateProvider.calendar

        // The 7 dates of the week that contains today.
        // Output: [Mon 26 Oct, Tue 27, Wed 28, Thu 29, Fri 30, Sat 31, Sun 1 Nov]
        let weekDates = WeekCalculator(calendar: calendar).weekDates(containing: today)

        // One day per date; `plans` only add workouts to those days.
        // Output: 7 ScheduledDays (workouts empty when `plans` is empty)
        return WeeklySchedule(weekDates: weekDates, plans: plans, today: today, calendar: calendar)
    }
}
