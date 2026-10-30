import Foundation
import SwiftData
import Testing
@testable import EverfitTest

/// Real repository over a stub network client and an in-memory SwiftData store.
@MainActor
struct WorkoutRepositoryTests {
    /// Shared by every repository in a test, so the cache outlives a single instance (like an app relaunch).
    private let modelContainer = SwiftDataStack.makeContainer(inMemory: true)

    private func makeRepository(_ result: Result<any Sendable, APIError>) -> DefaultWorkoutRepository {
        DefaultWorkoutRepository(networkClient: StubNetworkClient(result: result), store: SwiftDataStore(modelContainer: modelContainer))
    }

    @Test func noCacheBeforeFirstSuccessfulFetch() {
        #expect(makeRepository(.failure(.noInternet)).cachedWeek() == nil)
    }

    @Test func fetchReturnsFreshData() async throws {
        let week = try await makeRepository(.success(try Fixtures.response())).fetchWeek()

        #expect(week.map(\.weekday) == [0, 1, 2])
        #expect(week[0].workouts.map(\.id) == ["w1"])
    }

    @Test func successfulFetchIsCachedForNextLaunch() async throws {
        _ = try await makeRepository(.success(try Fixtures.response())).fetchWeek()

        // New repository over the same store, offline.
        let cached = try #require(makeRepository(.failure(.noInternet)).cachedWeek())

        #expect(cached.map(\.weekday) == [0, 1, 2])
        #expect(cached[0].workouts.map(\.id) == ["w1"])
        #expect(cached[1].workouts.first?.isCompleted == true)
    }

    @Test func failedFetchThrowsAndKeepsCache() async throws {
        _ = try await makeRepository(.success(try Fixtures.response())).fetchWeek()
        let offline = makeRepository(.failure(.noInternet))

        await #expect(throws: APIError.noInternet) {
            try await offline.fetchWeek()
        }
        #expect(offline.cachedWeek()?.map(\.weekday) == [0, 1, 2])
    }

    @Test func newerFetchReplacesCache() async throws {
        _ = try await makeRepository(.success(try Fixtures.response())).fetchWeek()
        _ = try await makeRepository(.success(Fixtures.response(day: 4, workoutIDs: ["new"]))).fetchWeek()

        let cached = try #require(makeRepository(.failure(.noInternet)).cachedWeek())

        #expect(cached.map(\.weekday) == [4])
        #expect(cached[0].workouts.map(\.id) == ["new"])
    }

    @Test func unreadableCacheCountsAsNoCacheAndIsReplacedByNextFetch() async throws {
        let context = modelContainer.mainContext
        context.insert(CachedResponse(payload: Data("not json".utf8)))
        try context.save()

        #expect(makeRepository(.failure(.noInternet)).cachedWeek() == nil)

        _ = try await makeRepository(.success(try Fixtures.response())).fetchWeek()

        #expect(makeRepository(.failure(.noInternet)).cachedWeek()?.map(\.weekday) == [0, 1, 2])
        #expect(try context.fetchCount(FetchDescriptor<CachedResponse>()) == 1)
    }

    @Test func emptyResponseIsCachedAsAnEmptyWeek() async throws {
        let week = try await makeRepository(.success(APIResponse<[DayDTO]>(data: [], message: nil))).fetchWeek()

        #expect(week.isEmpty)
        // Cached but empty, not "no cache": the next launch shows an empty week instead of loading.
        #expect(makeRepository(.failure(.noInternet)).cachedWeek() == [])
    }

    @Test(.timeLimit(.minutes(1))) func failedCacheWriteStillReturnsFreshData() async throws {
        // A store that rejects every save: create it on disk, then reopen it read-only.
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try ModelContainer(for: SwiftDataStack.schema, configurations: ModelConfiguration(url: url))
        let readOnly = try ModelContainer(
            for: SwiftDataStack.schema,
            configurations: ModelConfiguration(url: url, allowsSave: false)
        )
        let probe = ModelContext(readOnly)
        probe.insert(CachedResponse(payload: Data()))
        #expect(throws: (any Error).self) { try probe.save() }
        let repository = DefaultWorkoutRepository(
            networkClient: StubNetworkClient(result: .success(try Fixtures.response())),
            store: SwiftDataStore(modelContainer: readOnly)
        )

        let week = try await repository.fetchWeek()

        #expect(week.map(\.weekday) == [0, 1, 2])
    }

    // MARK: - Completion toggles (fixture: w1 missed, w2 completed by the API)

    @Test func toggleIsMergedIntoCachedWeek() async throws {
        let repository = makeRepository(.success(try Fixtures.response()))
        _ = try await repository.fetchWeek()

        repository.setCompleted(true, workoutID: "w1")

        #expect(repository.cachedWeek()?[0].workouts.first?.isCompleted == true)
    }

    @Test func toggleSurvivesNewFetchThatOverwritesCache() async throws {
        let repository = makeRepository(.success(try Fixtures.response()))
        _ = try await repository.fetchWeek()
        repository.setCompleted(true, workoutID: "w1")

        let fresh = try await repository.fetchWeek()

        #expect(fresh[0].workouts.first?.isCompleted == true)
    }

    @Test func toggleSurvivesRelaunchOffline() async throws {
        let online = makeRepository(.success(try Fixtures.response()))
        _ = try await online.fetchWeek()
        online.setCompleted(true, workoutID: "w1")

        // New repository over the same store, offline.
        let cached = try #require(makeRepository(.failure(.noInternet)).cachedWeek())

        #expect(cached[0].workouts.first?.isCompleted == true)
    }

    @Test func canUnmarkWorkoutCompletedByAPI() async throws {
        let repository = makeRepository(.success(try Fixtures.response()))
        repository.setCompleted(false, workoutID: "w2")

        let fresh = try await repository.fetchWeek()

        #expect(fresh[1].workouts.first?.isCompleted == false)
    }

    @Test func lastToggleWins() async throws {
        let repository = makeRepository(.success(try Fixtures.response()))
        repository.setCompleted(true, workoutID: "w1")
        repository.setCompleted(false, workoutID: "w1")

        let fresh = try await repository.fetchWeek()

        #expect(fresh[0].workouts.first?.isCompleted == false)
    }
}
