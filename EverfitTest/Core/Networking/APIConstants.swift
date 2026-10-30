import Foundation

nonisolated enum APIConstants {
    static let baseURL = "https://mock.internalef.com"
    static let timeout: TimeInterval = 15
    /// GET requests are retried this many times on timeout / no connection / 5xx.
    static let retryLimit: UInt = 2

    /// Added to every request unless the request sets the same header itself.
    static let defaultHeaders: [String: String] = [
        "Accept": "application/json"
    ]

    enum Path {
        static let workouts = "/workouts"
    }
}
