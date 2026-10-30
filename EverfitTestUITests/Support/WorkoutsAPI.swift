import Foundation

/// One workout as the real API returns it this run — the source of every expected value.
struct APIWorkout: Sendable {
    let id: String
    let title: String
    /// 0 = Monday … 6 = Sunday.
    let day: Int
    /// 0 assigned, 1 missed, 2 completed.
    let status: Int
    let totalExercise: Int

    var exerciseCountText: String {
        totalExercise == 1 ? "1 exercise" : "\(totalExercise) exercises"
    }
}

/// Fetches `GET /workouts` directly, so UI tests compare the screen with live data instead of a copied fixture.
enum WorkoutsAPI {
    private struct Response: Decodable {
        let data: [Day]
    }

    private struct Day: Decodable {
        let day: Int
        let assignments: [Assignment]
    }

    private struct Assignment: Decodable {
        let id: String
        let title: String
        let status: Int
        let totalExercise: Int

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case title, status
            case totalExercise = "total_exercise"
        }
    }

    /// Workouts in API order, only for days 0–6 (the app ignores others).
    static func fetch() async throws -> [APIWorkout] {
        let url = try XCTUnwrapURL("https://mock.internalef.com/workouts")
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.data
            .filter { (0...6).contains($0.day) }
            .flatMap { day in
                day.assignments.map {
                    APIWorkout(id: $0.id, title: $0.title, day: day.day, status: $0.status, totalExercise: $0.totalExercise)
                }
            }
    }

    private static func XCTUnwrapURL(_ string: String) throws -> URL {
        guard let url = URL(string: string) else { throw URLError(.badURL) }
        return url
    }
}
