import Alamofire

nonisolated enum DefaultInterceptor {
    /// Retries GET requests on timeout / no connection / 5xx with exponential backoff (0.5s, 1s, ...).
    static func make(retryLimit: UInt) -> any RequestInterceptor {
        RetryPolicy(retryLimit: retryLimit, retryableHTTPMethods: [.get])
    }
}
