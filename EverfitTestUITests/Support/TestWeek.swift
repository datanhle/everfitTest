import Foundation

/// The current week computed independently from the app: Gregorian, Monday first, device time zone.
enum TestWeek {
    enum Relation {
        case past, today, future
    }

    /// "MON" … "SUN" as the app shows them in English.
    static let weekdayTexts = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    /// Today's index, 0 = Monday … 6 = Sunday (`Calendar` weekday is 1 = Sunday … 7 = Saturday).
    static var todayIndex: Int {
        (calendar.component(.weekday, from: Date()) + 5) % 7
    }

    /// Day of month for Monday … Sunday of this week.
    static var dayNumbers: [Int] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { index in
            calendar.date(byAdding: .day, value: index - todayIndex, to: today).map { calendar.component(.day, from: $0) }
        }
    }

    static func relation(ofDay day: Int) -> Relation {
        day < todayIndex ? .past : (day == todayIndex ? .today : .future)
    }

    /// The status word VoiceOver reads for an API workout this week (spec: status comes from the date + completion).
    static func expectedStatus(of workout: APIWorkout, completed: Bool? = nil) -> String {
        let isCompleted = completed ?? (workout.status == 2)
        switch relation(ofDay: workout.day) {
        case .past: return isCompleted ? "Completed" : "Missed"
        case .today: return isCompleted ? "Completed" : "Assigned"
        case .future: return "Upcoming"
        }
    }

    /// Full VoiceOver label of a card: "<title>, <status>, <N exercises>".
    static func expectedLabel(of workout: APIWorkout, completed: Bool? = nil) -> String {
        "\(workout.title), \(expectedStatus(of: workout, completed: completed)), \(workout.exerciseCountText)"
    }
}
