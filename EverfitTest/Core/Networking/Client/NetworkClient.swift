/// Common entry point for every API call in the app.
nonisolated protocol NetworkClient: Sendable {
    func send<Request: APIRequest>(_ request: Request) async throws(APIError) -> Request.Response
}
