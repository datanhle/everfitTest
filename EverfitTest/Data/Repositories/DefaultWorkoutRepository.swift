import Foundation
import SwiftData

/// Online and offline data share one shape: the API's `[DayDTO]`, stored as-is in SwiftData
/// (`CachedResponse`) and mapped to Domain by the same `DayDTO.toDomain()`.
/// The user's toggles live in `CompletionRecord` and are merged into every week returned.
final class DefaultWorkoutRepository: WorkoutRepository {
    private let networkClient: NetworkClient
    private let store: SwiftDataStore

    init(networkClient: NetworkClient, store: SwiftDataStore) {
        self.networkClient = networkClient
        self.store = store
    }

    func cachedWeek() -> [DayPlan]? {
        // An unreadable cache (e.g. an older format) counts as no cache; the next fetch overwrites it.
        guard let days = try? loadCache() else { return nil }
        return makePlans(days)
    }

    func fetchWeek() async throws(APIError) -> [DayPlan] {
        let days = try await networkClient.send(WorkoutsRequest()).data
        // A failed cache write should not hide fresh data.
        try? saveCache(days)
        return makePlans(days)
    }

    func setCompleted(_ isCompleted: Bool, workoutID: String) {
        // A failed write only loses the toggle on the next launch; the screen already shows it.
        try? saveCompletion(isCompleted, workoutID: workoutID)
    }

    /// API days → Domain plans, with the user's own marks applied.
    private func makePlans(_ days: [DayDTO]) -> [DayPlan] {
        let userCompletions = (try? loadCompletions()) ?? [:]
        return days.map { $0.toDomain(userCompletions: userCompletions) }
    }

    private func loadCache() throws -> [DayDTO]? {
        guard let cached = try store.first(CachedResponse.self) else { return nil }
        return try JSONDecoder().decode([DayDTO].self, from: cached.payload)
    }

    private func saveCache(_ days: [DayDTO]) throws {
        try store.replaceAll(with: CachedResponse(payload: try JSONEncoder().encode(days)))
    }

    private func loadCompletions() throws -> [String: Bool] {
        let records = try store.fetch(CompletionRecord.self)
        return Dictionary(records.map { ($0.workoutID, $0.isCompleted) }, uniquingKeysWith: { _, last in last })
    }

    private func saveCompletion(_ isCompleted: Bool, workoutID: String) throws {
        try store.upsert(
            where: #Predicate<CompletionRecord> { $0.workoutID == workoutID },
            update: { $0.isCompleted = isCompleted },
            create: { CompletionRecord(workoutID: workoutID, isCompleted: isCompleted) }
        )
    }
}
