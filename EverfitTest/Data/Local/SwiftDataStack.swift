import SwiftData

enum SwiftDataStack {
    static let schema = Schema([CachedResponse.self, CompletionRecord.self])

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory))
        } catch {
            // A broken on-disk store must not block the app: fall back to an in-memory cache.
            do {
                return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            } catch {
                fatalError("Unable to create in-memory ModelContainer: \(error)")
            }
        }
    }
}
