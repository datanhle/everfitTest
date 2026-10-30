import Foundation

/// The only error type that leaves the networking layer.
nonisolated enum APIError: Error, Equatable {
    case noInternet
    case timeout
    case cancelled
    case unauthorized
    case server(statusCode: Int, message: String?)
    case decoding
    case invalidRequest
    case unknown

    init(urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .noInternet
        case .timedOut:
            self = .timeout
        case .cancelled:
            self = .cancelled
        default:
            self = .unknown
        }
    }

    /// Maps a non-2xx response; reads the server message from `APIErrorResponse` when present.
    init(statusCode: Int, data: Data?) {
        if statusCode == 401 {
            self = .unauthorized
            return
        }
        let body = data.flatMap { try? JSONDecoder().decode(APIErrorResponse.self, from: $0) }
        self = .server(statusCode: statusCode, message: body?.message)
    }

    var userMessage: String {
        switch self {
        case .noInternet: AppStrings.Errors.noInternet
        case .timeout: AppStrings.Errors.timeout
        case .cancelled: AppStrings.Errors.cancelled
        case .unauthorized: AppStrings.Errors.unauthorized
        case .server(_, let message): message ?? AppStrings.Errors.server
        case .decoding: AppStrings.Errors.decoding
        case .invalidRequest, .unknown: AppStrings.Errors.unknown
        }
    }
}
