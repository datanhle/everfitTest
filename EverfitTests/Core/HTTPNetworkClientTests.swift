import Foundation
import Testing
@testable import EverfitTest

/// Runs the real Alamofire client against a stubbed URLProtocol — no network.
@Suite(.serialized)
struct HTTPNetworkClientTests {
    private func makeClient(status: Int, body: String, delay: TimeInterval = 0) -> HTTPNetworkClient {
        StubURLProtocol.response = (status, Data(body.utf8))
        StubURLProtocol.delay = delay
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return HTTPNetworkClient(configuration: configuration, retryLimit: 0)
    }

    @Test func decodesResponseAndSendsDefaultHeaders() async throws {
        let client = makeClient(status: 200, body: Fixtures.responseJSON)

        let response = try await client.send(WorkoutsRequest())

        #expect(response.data.count == 3)
        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.url?.absoluteString == APIConstants.baseURL + APIConstants.Path.workouts)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func non2xxBecomesServerErrorWithMessage() async {
        let client = makeClient(status: 404, body: #"{ "message": "Not found" }"#)

        await #expect(throws: APIError.server(statusCode: 404, message: "Not found")) {
            try await client.send(WorkoutsRequest())
        }
    }

    @Test func unexpectedBodyBecomesDecodingError() async {
        let client = makeClient(status: 200, body: #"{ "unexpected": true }"#)

        await #expect(throws: APIError.decoding) {
            try await client.send(WorkoutsRequest())
        }
    }

    @Test func cancellingTheTaskCancelsTheRequest() async throws {
        let client = makeClient(status: 200, body: Fixtures.responseJSON, delay: 5)
        let task = Task { try await client.send(WorkoutsRequest()) }
        try await Task.sleep(for: .milliseconds(100))

        task.cancel()

        await #expect(throws: APIError.cancelled) {
            try await task.value
        }
    }
}

final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var response: (status: Int, data: Data) = (200, Data())
    nonisolated(unsafe) static var lastRequest: URLRequest?
    /// Seconds before responding, so a test can cancel in between.
    nonisolated(unsafe) static var delay: TimeInterval = 0
    private var isStopped = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard Self.delay > 0 else { return respond() }
        DispatchQueue.global().asyncAfter(deadline: .now() + Self.delay) { [weak self] in
            guard let self, !self.isStopped else { return }
            self.respond()
        }
    }

    private func respond() {
        guard let url = request.url,
              let httpResponse = HTTPURLResponse(url: url, statusCode: Self.response.status, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else { return }
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.response.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        isStopped = true
    }
}
