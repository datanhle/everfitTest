import Foundation
import SwiftData

/// Last successful `GET /workouts` payload (`[DayDTO]` as JSON). At most one row.
@Model
final class CachedResponse {
    var payload: Data

    init(payload: Data) {
        self.payload = payload
    }
}
