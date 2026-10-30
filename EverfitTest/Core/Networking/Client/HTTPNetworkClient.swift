import Alamofire
import Foundation

/// Alamofire-backed client. The network call runs on URLSession's threads and decoding on
/// Alamofire's serialization queue, so the main actor only awaits the result.
/// Cancelling the calling Task cancels the underlying request.
nonisolated final class HTTPNetworkClient: NetworkClient {
    private let session: Session

    init(configuration: URLSessionConfiguration = .af.default, retryLimit: UInt = APIConstants.retryLimit) {
        configuration.timeoutIntervalForRequest = APIConstants.timeout
        session = Session(
            configuration: configuration,
            interceptor: DefaultInterceptor.make(retryLimit: retryLimit),
            eventMonitors: [NetworkLogger()]
        )
    }

    func send<Request: APIRequest>(_ request: Request) async throws(APIError) -> Request.Response {
        let task = session.request(
            APIConstants.baseURL + request.path,
            method: HTTPMethod(rawValue: request.method.rawValue),
            parameters: request.parameters,
            encoding: request.encoding.alamofire,
            // Request-specific headers override the common ones.
            headers: HTTPHeaders(APIConstants.defaultHeaders.merging(request.headers) { _, own in own })
        )
        .validate()
        .serializingDecodable(Request.Response.self, automaticallyCancelling: true)

        let response = await task.response
        switch response.result {
        case .success(let value):
            return value
        case .failure(let error):
            throw APIError(error, statusCode: response.response?.statusCode, data: response.data)
        }
    }
}

private nonisolated extension RequestEncoding {
    var alamofire: any ParameterEncoding {
        switch self {
        case .url: URLEncoding.default
        case .json: JSONEncoding.default
        }
    }
}

private nonisolated extension APIError {
    init(_ error: AFError, statusCode: Int?, data: Data?) {
        if error.isExplicitlyCancelledError {
            self = .cancelled
        } else if let urlError = error.underlyingError as? URLError {
            self = APIError(urlError: urlError)
        } else if let statusCode, !(200..<300).contains(statusCode) {
            self = APIError(statusCode: statusCode, data: data)
        } else if error.isResponseSerializationError || error.isResponseValidationError {
            // 2xx with a body we can't use (bad JSON or wrong Content-Type).
            self = .decoding
        } else if error.isInvalidURLError {
            self = .invalidRequest
        } else {
            self = .unknown
        }
    }
}
