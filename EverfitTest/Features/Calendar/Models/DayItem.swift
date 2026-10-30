import Foundation

/// Ready-to-render state for one day cell.
struct DayItem: Identifiable, Equatable {
    let id: Date
    let weekdayText: String
    let dayNumberText: String
    let isToday: Bool
    let workouts: [WorkoutItem]
}
