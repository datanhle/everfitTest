import Foundation
import Testing
@testable import EverfitTest

struct APIErrorTests {
    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, APIError.noInternet),
        (.networkConnectionLost, .noInternet),
        (.timedOut, .timeout),
        (.cancelled, .cancelled),
        (.badServerResponse, .unknown)
    ])
    func mapsURLErrors(code: URLError.Code, expected: APIError) {
        #expect(APIError(urlError: URLError(code)) == expected)
    }

    @Test func unauthorized() {
        #expect(APIError(statusCode: 401, data: nil) == .unauthorized)
    }

    @Test func serverErrorReadsMessageFromBody() {
        let body = Data(#"{ "message": "Maintenance", "code": 42 }"#.utf8)
        #expect(APIError(statusCode: 503, data: body) == .server(statusCode: 503, message: "Maintenance"))
    }

    @Test func serverErrorWithUnreadableBodyFallsBackToGenericMessage() {
        let error = APIError(statusCode: 500, data: Data("<html>".utf8))
        #expect(error == .server(statusCode: 500, message: nil))
        #expect(error.userMessage == AppStrings.Errors.server)
    }
}
