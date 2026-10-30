import Foundation
import Testing
@testable import EverfitTest

struct WeekCalculatorTests {
    private let calculator = WeekCalculator(calendar: TestCalendar.calendar)
    private let calendar = TestCalendar.calendar

    @Test func midweekReturnsMondayToSunday() {
        let dates = calculator.weekDates(containing: TestCalendar.date(2026, 10, 29)) // Thursday

        #expect(dates.count == 7)
        #expect(calendar.isDate(dates.first!, inSameDayAs: TestCalendar.date(2026, 10, 26)))
        #expect(calendar.isDate(dates.last!, inSameDayAs: TestCalendar.date(2026, 11, 1)))
    }

    @Test func sundayBelongsToWeekStartingPreviousMonday() {
        let dates = calculator.weekDates(containing: TestCalendar.date(2026, 11, 1)) // Sunday

        #expect(calendar.isDate(dates.first!, inSameDayAs: TestCalendar.date(2026, 10, 26)))
    }

    @Test func weekCrossingYearBoundary() {
        let dates = calculator.weekDates(containing: TestCalendar.date(2026, 12, 31))

        #expect(calendar.isDate(dates.first!, inSameDayAs: TestCalendar.date(2026, 12, 28)))
        #expect(calendar.isDate(dates.last!, inSameDayAs: TestCalendar.date(2027, 1, 3)))
    }
}
