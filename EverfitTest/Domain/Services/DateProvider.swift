import Foundation

/// Injectable clock so "today" is controllable in tests and previews.
/// Implementations live in `Core/Utilities`.
nonisolated protocol DateProvider: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}
