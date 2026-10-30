import Foundation

nonisolated struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
    let calendar: Calendar = .mondayFirst
}
