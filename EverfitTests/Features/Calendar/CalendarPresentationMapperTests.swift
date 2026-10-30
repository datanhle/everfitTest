import Foundation
import Testing
@testable import EverfitTest

@MainActor
struct CalendarPresentationMapperTests {
    private let calendar = TestCalendar.calendar
    private let today = TestCalendar.date(2026, 10, 29) // Thursday

    private func makeSchedule(plans: [DayPlan]) -> WeeklySchedule {
        let weekDates = WeekCalculator(calendar: calendar).weekDates(containing: today)
        return WeeklySchedule(weekDates: weekDates, plans: plans, today: today, calendar: calendar)
    }

    @Test func mapsWeekdaysStartingOnMonday() {
        let items = CalendarPresentationMapper.map(makeSchedule(plans: []), locale: Locale(identifier: "en_US"))

        #expect(items.map(\.weekdayText) == ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"])
        #expect(items.map(\.dayNumberText) == ["26", "27", "28", "29", "30", "31", "1"])
        #expect(items.map(\.isToday) == [false, false, false, true, false, false, false])
    }

    @Test func mapsWorkoutFields() throws {
        let schedule = makeSchedule(plans: [DayPlan(weekday: 0, workouts: [Fixtures.workout(id: "w1")])])

        let workout = try #require(CalendarPresentationMapper.map(schedule).first?.workouts.first)

        #expect(workout.id == "w1")
        #expect(workout.title == "Workout w1")
        #expect(workout.exerciseCountText == AppStrings.CalendarScreen.exerciseCount(3))
        #expect(workout.status == .missed)
        #expect(workout.isCompleted == false)
        #expect(workout.canToggle)
    }

    @Test func futureWorkoutIsNotTappable() throws {
        let schedule = makeSchedule(plans: [DayPlan(weekday: 6, workouts: [Fixtures.workout(id: "future")])])

        let workout = try #require(CalendarPresentationMapper.map(schedule)[6].workouts.first)

        #expect(workout.status == .upcoming)
        #expect(!workout.canToggle)
    }

    /// Figma: only missed and completed show a status word; assigned and future show the count only.
    @Test func statusLabelsFollowDesign() {
        #expect(ScheduleStatus.missed.label == AppStrings.Status.missed)
        #expect(ScheduleStatus.completed.label == AppStrings.Status.completed)
        #expect(ScheduleStatus.assigned.label == nil)
        #expect(ScheduleStatus.upcoming.label == nil)
        #expect(ScheduleStatus.assigned.accessibilityName == AppStrings.Status.assigned)
        #expect(!ScheduleStatus.completed.showsExerciseCount)
        #expect(ScheduleStatus.missed.showsExerciseCount)
    }
}
