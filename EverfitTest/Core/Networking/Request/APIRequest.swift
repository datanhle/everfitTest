/// Base request. Each endpoint is one small type conforming to this protocol.
/// Uses app-owned types only, so callers never import Alamofire.
nonisolated protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    var path: String { get }
    var method: RequestMethod { get }
    var parameters: [String: any Sendable]? { get }
    var encoding: RequestEncoding { get }
    /// Request-specific headers. Common headers come from `APIConstants.defaultHeaders`.
    var headers: [String: String] { get }
}

nonisolated extension APIRequest {
    var method: RequestMethod { .get }
    var parameters: [String: any Sendable]? { nil }
    var encoding: RequestEncoding { method == .get ? .url : .json }
    var headers: [String: String] { [:] }
}
