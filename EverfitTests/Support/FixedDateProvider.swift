import Foundation
@testable import EverfitTest

/// Frozen clock for tests.
nonisolated struct FixedDateProvider: DateProvider {
    let now: Date
    var calendar: Calendar = .mondayFirst
}
