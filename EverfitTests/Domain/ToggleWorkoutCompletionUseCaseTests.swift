import Testing
@testable import EverfitTest

@MainActor
struct ToggleWorkoutCompletionUseCaseTests {
    /// Thursday 2026-10-29 → Mon 26 is past, Thu 29 is today, Sun 1 is future.
    private let today = TestCalendar.date(2026, 10, 29)

    private func schedule(_ plans: [DayPlan]) -> WeeklySchedule {
        let weekDates = WeekCalculator(calendar: TestCalendar.calendar).weekDates(containing: today)
        return WeeklySchedule(weekDates: weekDates, plans: plans, today: today, calendar: TestCalendar.calendar)
    }

    @Test func marksPastWorkoutCompletedAndSavesIt() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w")])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: before)

        #expect(before.workout(withID: "w")?.status == .missed)
        #expect(after.workout(withID: "w")?.isCompleted == true)
        #expect(after.workout(withID: "w")?.status == .completed)
        #expect(repository.savedCompletions == ["w": true])
    }

    @Test func unmarksCompletedWorkout() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "w", isCompleted: true)])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: before)

        #expect(after.workout(withID: "w")?.isCompleted == false)
        #expect(after.workout(withID: "w")?.status == .assigned)
        #expect(repository.savedCompletions == ["w": false])
    }

    @Test func futureWorkoutCannotBeMarked() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 6, workouts: [Fixtures.workout(id: "w")])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: before)

        #expect(before.workout(withID: "w")?.canToggleCompletion == false)
        #expect(after == before)
        #expect(repository.savedCompletions.isEmpty)
    }

    @Test func pastAndTodayWorkoutsCanBeMarked() {
        let week = schedule([
            DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "past")]),
            DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "today")])
        ])

        #expect(week.workout(withID: "past")?.canToggleCompletion == true)
        #expect(week.workout(withID: "today")?.canToggleCompletion == true)
    }

    @Test func onlyTheTappedWorkoutChanges() {
        let before = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "a"), Fixtures.workout(id: "b")])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: StubWorkoutRepository(.success([])))
            .execute(workoutID: "a", in: before)

        #expect(after.workout(withID: "a")?.isCompleted == true)
        #expect(after.workout(withID: "b") == before.workout(withID: "b"))
    }

    @Test func unknownIDChangesAndSavesNothing() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w")])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "missing", in: before)

        #expect(after == before)
        #expect(repository.savedCompletions.isEmpty)
    }

    @Test func marksTodayWorkoutCompletedAndSavesIt() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "w")])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: before)

        #expect(before.workout(withID: "w")?.status == .assigned)
        #expect(after.workout(withID: "w")?.status == .completed)
        #expect(repository.savedCompletions == ["w": true])
    }

    @Test func unmarksPastWorkoutBackToMissed() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w", isCompleted: true)])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: before)

        #expect(after.workout(withID: "w")?.status == .missed)
        #expect(repository.savedCompletions == ["w": false])
    }

    @Test func secondTapRestoresOriginalAndSavesLastValue() {
        let repository = StubWorkoutRepository(.success([]))
        let useCase = DefaultToggleWorkoutCompletionUseCase(repository: repository)
        let before = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w")])])

        let after = useCase.execute(workoutID: "w", in: useCase.execute(workoutID: "w", in: before))

        #expect(after == before)
        #expect(repository.savedCompletions == ["w": false])
    }

    @Test func originalScheduleIsNotChanged() {
        let before = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w")])])

        _ = DefaultToggleWorkoutCompletionUseCase(repository: StubWorkoutRepository(.success([])))
            .execute(workoutID: "w", in: before)

        #expect(before.workout(withID: "w")?.isCompleted == false)
        #expect(before.workout(withID: "w")?.status == .missed)
    }

    @Test func futureWorkoutCompletedByAPIStaysReadOnly() {
        let repository = StubWorkoutRepository(.success([]))
        let before = schedule([DayPlan(weekday: 6, workouts: [Fixtures.workout(id: "w", isCompleted: true)])])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: before)

        #expect(after == before)
        #expect(after.workout(withID: "w")?.status == .upcoming)
        #expect(repository.savedCompletions.isEmpty)
    }

    @Test func tapBeforeDataIsLoadedDoesNothing() {
        let repository = StubWorkoutRepository(.success([]))
        let empty = schedule([])

        let after = DefaultToggleWorkoutCompletionUseCase(repository: repository).execute(workoutID: "w", in: empty)

        #expect(after == empty)
        #expect(repository.savedCompletions.isEmpty)
    }
}
