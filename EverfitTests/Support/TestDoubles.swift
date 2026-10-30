import Foundation
@testable import EverfitTest

enum TestCalendar {
    /// Monday-first, UTC, so dates are deterministic on any machine.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}

nonisolated struct StubNetworkClient: NetworkClient {
    let result: Result<any Sendable, APIError>

    func send<Request: APIRequest>(_ request: Request) async throws(APIError) -> Request.Response {
        try result.get() as! Request.Response
    }
}

@MainActor
final class StubWorkoutRepository: WorkoutRepository {
    let cached: [DayPlan]?
    let result: Result<[DayPlan], APIError>
    /// Runs when `fetchWeek()` starts, i.e. after the cache has been shown.
    var onFetch: (() -> Void)?
    /// Every `setCompleted` call, latest value per workout ID.
    private(set) var savedCompletions: [String: Bool] = [:]

    init(cached: [DayPlan]? = nil, _ result: Result<[DayPlan], APIError>) {
        self.cached = cached
        self.result = result
    }

    func cachedWeek() -> [DayPlan]? {
        cached
    }

    func fetchWeek() async throws(APIError) -> [DayPlan] {
        onFetch?()
        return try result.get()
    }

    func setCompleted(_ isCompleted: Bool, workoutID: String) {
        savedCompletions[workoutID] = isCompleted
    }
}

/// Every `fetchWeek()` waits until the test resumes it, so loads can overlap and finish in any order.
@MainActor
final class GatedWorkoutRepository: WorkoutRepository {
    private var pendingFetches: [CheckedContinuation<Result<[DayPlan], APIError>, Never>] = []

    func cachedWeek() -> [DayPlan]? {
        nil
    }

    func fetchWeek() async throws(APIError) -> [DayPlan] {
        try await withCheckedContinuation { pendingFetches.append($0) }.get()
    }

    func setCompleted(_ isCompleted: Bool, workoutID: String) {}

    /// Waits until `count` fetches have started.
    func waitForFetches(_ count: Int) async {
        while pendingFetches.count < count { await Task.yield() }
    }

    /// Finishes the fetch that started `index`-th (0 = first).
    func finishFetch(_ index: Int, with result: Result<[DayPlan], APIError>) {
        pendingFetches[index].resume(returning: result)
    }
}

enum Fixtures {
    static let responseJSON = """
    {
      "data": [
        { "_id": "d0", "day": 0, "assignments": [
          { "_id": "w1", "title": "Legs day", "status": 1, "total_exercise": 5 }
        ]},
        { "_id": "d1", "day": 1, "assignments": [
          { "_id": "w2", "title": "Full warm up workout", "status": 2, "total_exercise": 6 }
        ]},
        { "_id": "d2", "day": 2, "assignments": [] }
      ]
    }
    """

    static func response() throws -> WorkoutsRequest.Response {
        try JSONDecoder().decode(WorkoutsRequest.Response.self, from: Data(responseJSON.utf8))
    }

    /// A one-day response, for checking that a newer response replaces the cache.
    static func response(day: Int, workoutIDs: [String]) -> WorkoutsRequest.Response {
        let assignments = workoutIDs.map { AssignmentDTO(id: $0, title: "Workout \($0)", status: 0, totalExercise: 3) }
        return APIResponse(data: [DayDTO(id: "d\(day)", day: day, assignments: assignments)], message: nil)
    }

    static func workout(id: String, isCompleted: Bool = false) -> Workout {
        Workout(id: id, title: "Workout \(id)", exerciseCount: 3, isCompleted: isCompleted)
    }
}
