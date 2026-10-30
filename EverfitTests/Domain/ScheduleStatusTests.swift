import Foundation
import Testing
@testable import EverfitTest

struct ScheduleStatusTests {
    @Test(arguments: [
        (DayRelation.past, false, ScheduleStatus.missed),
        (.past, true, .completed),
        (.today, false, .assigned),
        (.today, true, .completed),
        (.future, false, .upcoming),
        (.future, true, .upcoming)
    ])
    func rule(relation: DayRelation, isCompleted: Bool, expected: ScheduleStatus) {
        #expect(ScheduleStatus(relation: relation, isCompleted: isCompleted) == expected)
    }

    @Test func dayRelationIgnoresTimeOfDay() {
        let today = TestCalendar.date(2026, 10, 29, hour: 15)
        let relation = { (date: Date) in DayRelation(date: date, today: today, calendar: TestCalendar.calendar) }

        #expect(relation(TestCalendar.date(2026, 10, 28, hour: 23)) == .past)
        #expect(relation(TestCalendar.date(2026, 10, 29, hour: 0)) == .today)
        #expect(relation(TestCalendar.date(2026, 10, 30, hour: 0)) == .future)
    }
}
