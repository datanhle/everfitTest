import Alamofire
import Foundation
import OSLog

/// Logs every request and response in DEBUG builds.
nonisolated final class NetworkLogger: EventMonitor {
    let queue = DispatchQueue(label: "com.everfit.network-logger")
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "EverfitTest", category: "Network")

    func requestDidResume(_ request: Request) {
        #if DEBUG
        logger.debug("➡️ \(request.description)")
        #endif
    }

    func request<Value: Sendable>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        #if DEBUG
        let status = response.response?.statusCode.description ?? "-"
        switch response.result {
        case .success:
            logger.debug("✅ [\(status)] \(request.description)")
        case .failure(let error):
            logger.error("❌ [\(status)] \(request.description) — \(error.localizedDescription)")
        }
        #endif
    }
}
