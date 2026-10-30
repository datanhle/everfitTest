import Foundation
import Testing
@testable import EverfitTest

@MainActor
struct LoadWeeklyScheduleUseCaseTests {
    /// Thursday 2026-10-29 → week Mon 26 ... Sun 1.
    private let dateProvider = FixedDateProvider(now: TestCalendar.date(2026, 10, 29), calendar: TestCalendar.calendar)

    private func makeUseCase(_ result: Result<[DayPlan], APIError>) -> DefaultLoadWeeklyScheduleUseCase {
        DefaultLoadWeeklyScheduleUseCase(repository: StubWorkoutRepository(result), dateProvider: dateProvider)
    }

    @Test func emptyWeekHasSevenDatedDaysMondayFirst() {
        let schedule = makeUseCase(.success([])).emptyWeek()

        #expect(schedule.days.map(\.dayOfMonth) == [26, 27, 28, 29, 30, 31, 1])
        #expect(schedule.days.map(\.weekday) == Array(0...6))
        #expect(schedule.days.map(\.relation) == [.past, .past, .past, .today, .future, .future, .future])
        #expect(schedule.days.allSatisfy { $0.workouts.isEmpty })
    }

    @Test func matchesPlansByWeekdayAndResolvesStatus() async throws {
        let week = [
            DayPlan(weekday: 1, workouts: [Fixtures.workout(id: "tue"), Fixtures.workout(id: "tue-done", isCompleted: true)]),
            DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "thu")])
        ]

        let schedule = try await makeUseCase(.success(week)).fetchSchedule()

        #expect(schedule.days[1].workouts.map(\.status) == [.missed, .completed])
        #expect(schedule.days[3].workouts.map(\.status) == [.assigned])
        #expect(schedule.days[0].workouts.isEmpty)
    }

    @Test func cachedScheduleIsNilWithoutCache() {
        #expect(makeUseCase(.success([])).cachedSchedule() == nil)
    }

    @Test func cachedScheduleUsesCachedWeek() throws {
        let cached = [DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "cached")])]
        let useCase = DefaultLoadWeeklyScheduleUseCase(
            repository: StubWorkoutRepository(cached: cached, .failure(.noInternet)),
            dateProvider: dateProvider
        )

        let schedule = try #require(useCase.cachedSchedule())

        #expect(schedule.days.count == 7)
        #expect(schedule.days[3].workouts.map(\.id) == ["cached"])
        #expect(schedule.days[3].workouts.map(\.status) == [.assigned])
    }

    @Test func cachedEmptyWeekIsSevenEmptyDaysNotNil() throws {
        let useCase = DefaultLoadWeeklyScheduleUseCase(
            repository: StubWorkoutRepository(cached: [], .failure(.noInternet)),
            dateProvider: dateProvider
        )

        let schedule = try #require(useCase.cachedSchedule())

        #expect(schedule.days.map(\.dayOfMonth) == [26, 27, 28, 29, 30, 31, 1])
        #expect(schedule.days.allSatisfy { $0.workouts.isEmpty })
    }

    @Test func emptyResponseIsSevenEmptyDays() async throws {
        let schedule = try await makeUseCase(.success([])).fetchSchedule()

        #expect(schedule.days.count == 7)
        #expect(schedule.days.allSatisfy { $0.workouts.isEmpty })
    }

    @Test func fetchReturnsFreshDataNotCache() async throws {
        let useCase = DefaultLoadWeeklyScheduleUseCase(
            repository: StubWorkoutRepository(
                cached: [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "cached")])],
                .success([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "fresh")])])
            ),
            dateProvider: dateProvider
        )

        let schedule = try await useCase.fetchSchedule()

        #expect(schedule.days[0].workouts.map(\.id) == ["fresh"])
    }

    @Test(arguments: [
        TestCalendar.date(2026, 10, 26, hour: 0),
        TestCalendar.date(2026, 11, 1, hour: 23)
    ])
    func weekStartsMondayWhenTodayIsFirstOrLastDay(today: Date) {
        let useCase = DefaultLoadWeeklyScheduleUseCase(
            repository: StubWorkoutRepository(.success([])),
            dateProvider: FixedDateProvider(now: today, calendar: TestCalendar.calendar)
        )

        let days = useCase.emptyWeek().days

        #expect(days.map(\.dayOfMonth) == [26, 27, 28, 29, 30, 31, 1])
        #expect(days.filter { $0.relation == .today }.count == 1)
        #expect(days.first { $0.relation == .today }?.dayOfMonth == TestCalendar.calendar.component(.day, from: today))
    }

    @Test(arguments: [
        APIError.noInternet, .timeout, .cancelled, .unauthorized,
        .server(statusCode: 500, message: "Down"), .decoding, .unknown
    ])
    func forwardsRepositoryErrorUnchanged(error: APIError) async {
        await #expect(throws: error) {
            try await makeUseCase(.failure(error)).fetchSchedule()
        }
    }
}
