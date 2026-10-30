import Foundation
import SwiftData

/// The user's local mark/unmark of one workout, keyed by its API `_id`.
/// Kept apart from `CachedResponse` so a fetch that overwrites the cache never wipes it.
/// Stores the value (not just "marked") so a workout the API says is completed can be unmarked.
@Model
final class CompletionRecord {
    var workoutID: String
    var isCompleted: Bool

    init(workoutID: String, isCompleted: Bool) {
        self.workoutID = workoutID
        self.isCompleted = isCompleted
    }
}
