import Observation
import Testing
@testable import EverfitTest

/// Uses the real use case over a stub repository: tests presentation state, not data access.
@MainActor
struct CalendarViewModelTests {
    /// Thursday 2026-10-29 → week Mon 26 ... Sun 1.
    private let dateProvider = FixedDateProvider(now: TestCalendar.date(2026, 10, 29), calendar: TestCalendar.calendar)

    private func makeViewModel(_ repository: WorkoutRepository) -> CalendarViewModel {
        CalendarViewModel(
            loadSchedule: DefaultLoadWeeklyScheduleUseCase(repository: repository, dateProvider: dateProvider),
            toggleCompletion: DefaultToggleWorkoutCompletionUseCase(repository: repository)
        )
    }

    private func makeViewModel(_ result: Result<[DayPlan], APIError>) -> CalendarViewModel {
        makeViewModel(StubWorkoutRepository(result))
    }

    @Test func showsSevenDatedDaysWhileLoading() {
        let viewModel = makeViewModel(.success([]))

        #expect(viewModel.isLoading)
        #expect(viewModel.days.count == 7)
        #expect(viewModel.days.map(\.dayNumberText) == ["26", "27", "28", "29", "30", "31", "1"])
        #expect(viewModel.days.map(\.isToday) == [false, false, false, true, false, false, false])
    }

    @Test func mapsScheduleToItems() async {
        let week = [
            DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "past")]),
            DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "today")]),
            DayPlan(weekday: 6, workouts: [Fixtures.workout(id: "future")])
        ]
        let viewModel = makeViewModel(.success(week))

        await viewModel.load()

        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.days[0].workouts.first?.status == .missed)
        #expect(viewModel.days[3].workouts.first?.status == .assigned)
        #expect(viewModel.days[6].workouts.first?.status == .upcoming)
        #expect(viewModel.days[3].workouts.first?.exerciseCountText == AppStrings.CalendarScreen.exerciseCount(3))
    }

    @Test func showsCacheBeforeNetworkThenFreshData() async {
        let repository = StubWorkoutRepository(
            cached: [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "cached")])],
            .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "fresh")])])
        )
        let viewModel = makeViewModel(repository)
        var shownWhileFetching: [String] = []
        var loadingWhileFetching = true
        repository.onFetch = {
            shownWhileFetching = viewModel.days[0].workouts.map(\.id)
            loadingWhileFetching = viewModel.isLoading
        }

        await viewModel.load()

        #expect(shownWhileFetching == ["cached"])
        #expect(!loadingWhileFetching)
        #expect(viewModel.days[0].workouts.map(\.id) == ["fresh"])
    }

    @Test func failedFetchKeepsCachedDataAndShowsError() async {
        let viewModel = makeViewModel(StubWorkoutRepository(
            cached: [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "cached")])],
            .failure(.noInternet)
        ))

        await viewModel.load()

        #expect(viewModel.days[0].workouts.map(\.id) == ["cached"])
        #expect(viewModel.errorMessage == AppStrings.Errors.noInternet)
        #expect(!viewModel.isLoading)
    }

    @Test func failureWithoutCacheShowsErrorAndStopsLoading() async {
        let viewModel = makeViewModel(.failure(.noInternet))

        await viewModel.load()

        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == AppStrings.Errors.noInternet)
        #expect(viewModel.days.count == 7)
    }

    @Test func cancellationShowsNoErrorAndKeepsCachedRows() async {
        let viewModel = makeViewModel(StubWorkoutRepository(
            cached: [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "cached")])],
            .failure(.cancelled)
        ))

        await viewModel.load()

        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
        #expect(viewModel.days[0].workouts.map(\.id) == ["cached"])
    }

    @Test func emptyResponseShowsSevenEmptyDays() async {
        let viewModel = makeViewModel(.success([]))

        await viewModel.load()

        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.days.count == 7)
        #expect(viewModel.days.allSatisfy { $0.workouts.isEmpty })
    }

    // MARK: - Overlapping loads (.task + pull-to-refresh)

    @Test func olderLoadFinishingLastDoesNotOverwriteNewerData() async {
        let repository = GatedWorkoutRepository()
        let viewModel = makeViewModel(repository)
        let first = Task { await viewModel.load() }
        await repository.waitForFetches(1)
        let second = Task { await viewModel.load() }
        await repository.waitForFetches(2)

        repository.finishFetch(1, with: .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "new")])]))
        await second.value
        repository.finishFetch(0, with: .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "old")])]))
        await first.value

        #expect(viewModel.days[0].workouts.map(\.id) == ["new"])
        #expect(!viewModel.isLoading)
    }

    @Test func olderLoadFailingLastShowsNoError() async {
        let repository = GatedWorkoutRepository()
        let viewModel = makeViewModel(repository)
        let first = Task { await viewModel.load() }
        await repository.waitForFetches(1)
        let second = Task { await viewModel.load() }
        await repository.waitForFetches(2)

        repository.finishFetch(1, with: .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "new")])]))
        await second.value
        repository.finishFetch(0, with: .failure(.timeout))
        await first.value

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.days[0].workouts.map(\.id) == ["new"])
    }

    @Test func loadingStaysUntilTheNewestLoadFinishes() async {
        let repository = GatedWorkoutRepository()
        let viewModel = makeViewModel(repository)
        let first = Task { await viewModel.load() }
        await repository.waitForFetches(1)
        let second = Task { await viewModel.load() }
        await repository.waitForFetches(2)

        repository.finishFetch(0, with: .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "old")])]))
        await first.value
        #expect(viewModel.isLoading)
        #expect(viewModel.days[0].workouts.isEmpty)

        repository.finishFetch(1, with: .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "new")])]))
        await second.value
        #expect(!viewModel.isLoading)
        #expect(viewModel.days[0].workouts.map(\.id) == ["new"])
    }

    @Test func refreshDoesNotGoBackToCache() async {
        let repository = StubWorkoutRepository(
            cached: [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "cached")])],
            .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "fresh")])])
        )
        let viewModel = makeViewModel(repository)
        await viewModel.load()
        var shownWhileRefreshing: [String] = []
        repository.onFetch = { shownWhileRefreshing = viewModel.days[0].workouts.map(\.id) }

        await viewModel.load()

        #expect(shownWhileRefreshing == ["fresh"])
    }

    @Test func unchangedFetchDoesNotUpdateDays() async {
        let week = [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "same")])]
        let repository = StubWorkoutRepository(cached: week, .success(week))
        let viewModel = makeViewModel(repository)
        let daysChanged = Flag()
        repository.onFetch = {
            withObservationTracking { _ = viewModel.days } onChange: { daysChanged.value = true }
        }

        await viewModel.load()

        #expect(!daysChanged.value)
        #expect(viewModel.days[0].workouts.map(\.id) == ["same"])
    }

    @Test func closingErrorAlertClearsMessage() async {
        let viewModel = makeViewModel(.failure(.timeout))
        await viewModel.load()
        #expect(viewModel.isShowingError)

        viewModel.isShowingError = false

        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isShowingError)
    }

    // MARK: - Toggle

    @Test func tapMarksWorkoutCompletedAndSavesIt() async {
        let repository = StubWorkoutRepository(.success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w")])]))
        let viewModel = makeViewModel(repository)
        await viewModel.load()
        #expect(viewModel.days[0].workouts.first?.status == .missed)

        viewModel.toggleCompletion(workoutID: "w")

        #expect(viewModel.days[0].workouts.first?.isCompleted == true)
        #expect(viewModel.days[0].workouts.first?.status == .completed)
        #expect(repository.savedCompletions["w"] == true)
    }

    @Test func secondTapUnmarks() async {
        let repository = StubWorkoutRepository(.success([DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "w")])]))
        let viewModel = makeViewModel(repository)
        await viewModel.load()

        viewModel.toggleCompletion(workoutID: "w")
        viewModel.toggleCompletion(workoutID: "w")

        #expect(viewModel.days[3].workouts.first?.isCompleted == false)
        #expect(viewModel.days[3].workouts.first?.status == .assigned)
        #expect(repository.savedCompletions["w"] == false)
    }

    @Test func tapBeforeDataIsShownDoesNothing() {
        let repository = StubWorkoutRepository(.success([]))
        let viewModel = makeViewModel(repository)

        viewModel.toggleCompletion(workoutID: "w")

        #expect(repository.savedCompletions.isEmpty)
    }
}

/// Set from `withObservationTracking`'s `@Sendable` onChange.
private final class Flag: @unchecked Sendable {
    var value = false
}
