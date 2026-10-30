import Foundation

/// Every user-facing string. Views never contain literals.
/// `nonisolated` so non-UI layers (e.g. `APIError.userMessage`) can read it.
nonisolated enum AppStrings {
    enum Common {
        static let loading = String(localized: "Loading…")
    }

    enum CalendarScreen {
        /// Between the status word and the exercise count: "Missed • 5 exercises".
        static let detailSeparator = String(localized: " • ")

        static func exerciseCount(_ count: Int) -> String {
            count == 1
                ? String(localized: "1 exercise")
                : String(localized: "\(count) exercises")
        }
    }

    enum Status {
        static let assigned = String(localized: "Assigned")
        static let completed = String(localized: "Completed")
        static let missed = String(localized: "Missed")
        static let upcoming = String(localized: "Upcoming")
    }

    enum Errors {
        static let noInternet = String(localized: "No internet connection.")
        static let timeout = String(localized: "The request timed out. Please try again.")
        static let cancelled = String(localized: "The request was cancelled.")
        static let unauthorized = String(localized: "Your session has expired.")
        static let server = String(localized: "Something went wrong on our side. Please try again.")
        static let decoding = String(localized: "Received unexpected data.")
        static let unknown = String(localized: "Couldn't load workouts.")
        static let title = String(localized: "Couldn't load workouts")
        static let close = String(localized: "Close")
    }

    enum Accessibility {
        static let markCompleted = String(localized: "Double tap to mark as completed")
        static let markNotCompleted = String(localized: "Double tap to mark as not completed")
        static let today = String(localized: "Today")
    }
}
