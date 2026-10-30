import Foundation
import SwiftData
import Testing
@testable import EverfitTest

/// Real store over an in-memory SwiftData container.
@MainActor
struct SwiftDataStoreTests {
    private let store = SwiftDataStore(modelContainer: SwiftDataStack.makeContainer(inMemory: true))

    @Test func emptyStoreReturnsNoRows() throws {
        #expect(try store.fetch(CompletionRecord.self).isEmpty)
        #expect(try store.first(CachedResponse.self) == nil)
    }

    @Test func fetchAndFirstFilterByPredicate() throws {
        try store.upsert(where: #Predicate<CompletionRecord> { $0.workoutID == "w1" }, update: { _ in }, create: { CompletionRecord(workoutID: "w1", isCompleted: true) })
        try store.upsert(where: #Predicate<CompletionRecord> { $0.workoutID == "w2" }, update: { _ in }, create: { CompletionRecord(workoutID: "w2", isCompleted: false) })

        let matching = try store.fetch(CompletionRecord.self, where: #Predicate { $0.workoutID == "w2" })
        let first = try store.first(CompletionRecord.self, where: #Predicate { $0.workoutID == "w1" })

        #expect(matching.map(\.workoutID) == ["w2"])
        #expect(first?.isCompleted == true)
        #expect(try store.first(CompletionRecord.self, where: #Predicate { $0.workoutID == "unknown" }) == nil)
    }

    @Test func replaceAllKeepsOnlyTheNewRow() throws {
        try store.replaceAll(with: CachedResponse(payload: Data("old".utf8)))

        try store.replaceAll(with: CachedResponse(payload: Data("new".utf8)))

        #expect(try store.fetch(CachedResponse.self).map(\.payload) == [Data("new".utf8)])
    }

    @Test func upsertInsertsWhenMissingAndUpdatesWithoutDuplicating() throws {
        let predicate = #Predicate<CompletionRecord> { $0.workoutID == "w1" }

        try store.upsert(where: predicate, update: { $0.isCompleted = true }, create: { CompletionRecord(workoutID: "w1", isCompleted: true) })
        try store.upsert(where: predicate, update: { $0.isCompleted = false }, create: { CompletionRecord(workoutID: "w1", isCompleted: true) })

        let records = try store.fetch(CompletionRecord.self)
        #expect(records.count == 1)
        #expect(records.first?.isCompleted == false)
    }

    @Test func failedSaveThrows() throws {
        // A store that rejects every save: create it on disk, then reopen it read-only.
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try ModelContainer(for: SwiftDataStack.schema, configurations: ModelConfiguration(url: url))
        let readOnly = SwiftDataStore(modelContainer: try ModelContainer(
            for: SwiftDataStack.schema,
            configurations: ModelConfiguration(url: url, allowsSave: false)
        ))

        #expect(throws: (any Error).self) { try readOnly.replaceAll(with: CachedResponse(payload: Data())) }
    }
}
