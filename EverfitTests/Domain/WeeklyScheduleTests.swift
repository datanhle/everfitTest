import Foundation
import Testing
@testable import EverfitTest

/// How the API's day plans become one dated week, including odd API data.
struct WeeklyScheduleTests {
    /// Thursday 2026-10-29 → Mon 26 is past, Thu 29 is today, Sun 1 is future.
    private let today = TestCalendar.date(2026, 10, 29)

    private func schedule(_ plans: [DayPlan]) -> WeeklySchedule {
        let weekDates = WeekCalculator(calendar: TestCalendar.calendar).weekDates(containing: today)
        return WeeklySchedule(weekDates: weekDates, plans: plans, today: today, calendar: TestCalendar.calendar)
    }

    private func ids(_ week: WeeklySchedule) -> [[String]] {
        week.days.map { $0.workouts.map(\.id) }
    }

    /// The API's status 1 (missed) is not trusted for display: only the date and completion decide it.
    @Test func apiMissedStatusFollowsTheDate() {
        let plans = [0, 3, 6].map { day in
            DayDTO(id: "d\(day)", day: day, assignments: [
                AssignmentDTO(id: "w\(day)", title: "W", status: WorkoutStatus.missed.rawValue, totalExercise: 3)
            ]).toDomain()
        }

        let week = schedule(plans)

        #expect(week.days[0].workouts.map(\.status) == [.missed])
        #expect(week.days[3].workouts.map(\.status) == [.assigned])
        #expect(week.days[6].workouts.map(\.status) == [.upcoming])
    }

    @Test func emptyPlansGiveSevenEmptyDays() {
        let week = schedule([])

        #expect(week.days.count == 7)
        #expect(week.days.allSatisfy { $0.workouts.isEmpty })
    }

    @Test func weekdayOutsideZeroToSixIsIgnored() {
        let week = schedule([
            DayPlan(weekday: -1, workouts: [Fixtures.workout(id: "before")]),
            DayPlan(weekday: 2, workouts: [Fixtures.workout(id: "kept")]),
            DayPlan(weekday: 7, workouts: [Fixtures.workout(id: "after")])
        ])

        #expect(week.days.count == 7)
        #expect(ids(week).flatMap { $0 } == ["kept"])
    }

    @Test func plansForTheSameWeekdayAreMerged() {
        let week = schedule([
            DayPlan(weekday: 1, workouts: [Fixtures.workout(id: "a")]),
            DayPlan(weekday: 1, workouts: [Fixtures.workout(id: "b")])
        ])

        #expect(ids(week)[1] == ["a", "b"])
    }

    @Test func repeatedWorkoutIDKeepsOnlyTheFirstOccurrence() {
        let week = schedule([
            DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "dup"), Fixtures.workout(id: "x")]),
            DayPlan(weekday: 2, workouts: [Fixtures.workout(id: "dup")])
        ])

        #expect(ids(week)[0] == ["dup", "x"])
        #expect(ids(week)[2].isEmpty)

        let toggled = week.settingCompletion(true, workoutID: "dup")
        #expect(toggled.days.flatMap(\.workouts).filter(\.isCompleted).map(\.id) == ["dup"])
    }

    // MARK: settingCompletion

    @Test func settingCompletionUpdatesStatusForTheDay() throws {
        let week = schedule([
            DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "past")]),
            DayPlan(weekday: 3, workouts: [Fixtures.workout(id: "today")])
        ])

        let marked = week
            .settingCompletion(true, workoutID: "past")
            .settingCompletion(true, workoutID: "today")
        #expect(marked.workout(withID: "past")?.status == .completed)
        #expect(marked.workout(withID: "today")?.status == .completed)

        let unmarked = marked
            .settingCompletion(false, workoutID: "past")
            .settingCompletion(false, workoutID: "today")
        #expect(unmarked.workout(withID: "past")?.status == .missed)
        #expect(unmarked.workout(withID: "today")?.status == .assigned)
    }

    @Test func futureWorkoutStaysUpcomingWhenCompleted() {
        let week = schedule([DayPlan(weekday: 6, workouts: [Fixtures.workout(id: "future")])])

        let marked = week.settingCompletion(true, workoutID: "future")

        #expect(marked.workout(withID: "future")?.isCompleted == true)
        #expect(marked.workout(withID: "future")?.status == .upcoming)
    }

    @Test func settingCompletionChangesOnlyThatWorkoutInACopy() {
        let week = schedule([
            DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "a"), Fixtures.workout(id: "b")]),
            DayPlan(weekday: 1, workouts: [Fixtures.workout(id: "c")])
        ])

        let marked = week.settingCompletion(true, workoutID: "b")

        #expect(marked.days.flatMap(\.workouts).filter(\.isCompleted).map(\.id) == ["b"])
        #expect(ids(marked) == ids(week))
        // The original value is untouched.
        #expect(week.days.flatMap(\.workouts).allSatisfy { !$0.isCompleted })
    }

    @Test func unknownWorkoutIDLeavesScheduleUnchanged() {
        let week = schedule([DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "a")])])

        #expect(week.settingCompletion(true, workoutID: "missing") == week)
    }
}
