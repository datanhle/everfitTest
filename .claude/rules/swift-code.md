---
paths:
  - "EverfitTest/**/*.swift"
  - "EverfitTests/**/*.swift"
---

# Swift code: networking, concurrency, style

> **Hard rules — MUST be followed, never "just this once".** Items marked 🔒 are checked by `.claude/hooks/check-swift-rules.sh` after every Edit/Write; a violation is sent back and must be fixed before continuing.

🔒 Enforced: no Combine · no `DispatchQueue` (outside `Core/Networking/Monitoring`) · no `Date()` (outside `SystemDateProvider`) · no `try!` / `as!` in app code.

## Networking — adding an endpoint
1. DTOs in `Data/Remote/DTOs/` — `nonisolated struct <Name>DTO: Codable, Sendable`, field names via `CodingKeys` matching the API exactly (`_id`, snake_case). One DTO per file.
2. Request in `Data/Remote/Requests/` — `nonisolated struct <Name>Request: APIRequest` with `typealias Response = APIResponse<DTO>`, `path` from `APIConstants.Path`. Defaults: GET, no parameters, URL/JSON encoding by method.
3. Mapper in `Data/Mappers/<DTO>Mapper.swift` — `extension <DTO> { func toDomain(…) -> Entity }`; unknown enum raw values map to a documented default.
4. The repository calls `try await networkClient.send(<Name>Request())`.
- Alamofire (SPM, 5.x) is imported ONLY in `Core/Networking/Client`, `Interceptors`, `Monitoring`. Everyone else uses app-owned types: `APIRequest`, `RequestMethod`, `RequestEncoding`, `APIResponse<T>`, `APIError`, `NetworkClient`.
- `NetworkClient.send` uses typed throws (`throws(APIError)`). Only `APIError` crosses layers; UI shows `error.userMessage` (strings in `AppStrings.Errors`), `.cancelled` is silent.
- `HTTPNetworkClient`: merges `APIConstants.defaultHeaders` (request headers win) → `.validate()` → `serializingDecodable(automaticallyCancelling: true)` → maps `AFError` to `APIError`. Task cancellation cancels the request.
- `DefaultInterceptor` = `RetryPolicy`: GET retries `APIConstants.retryLimit` times on timeout/offline/5xx. `NetworkLogger` logs in DEBUG. Common headers go in `APIConstants.defaultHeaders`, never per call site.
- `.validate()` checks `Content-Type` against `Accept: application/json`.

## Concurrency
- Default isolation is MainActor. Mark DTOs, requests, networking and other off-main types `nonisolated` and `Sendable`.
- async/await only — no Combine, no completion handlers, no `DispatchQueue`. `AsyncStream` only when something really emits more than once.
- Views start work with `.task {}` / `.refreshable {}`; a `Task {}` only for a button action.
- Typed throws (`throws(APIError)`) on networking, repositories and use cases.

## Safety
- No force unwraps, `try!` or `as!` outside tests and previews; handle the error or use `guard let` / `as?`.
- Local persistence writes use `try?` with a comment saying what is lost on failure.

## Code style
- Match the surrounding code: naming, comment density, idioms. Read a neighbouring file of the same kind before writing a new one.
- One main type per file, file named after it. Exceptions: a use-case protocol + its `Default` implementation share a file; a convenience `init` lives in an `extension` in the type's file; private subviews stay with their View.
- Naming:
  | Kind | Name |
  |---|---|
  | Protocol | by role: `<X>Repository`, `<Action>UseCase`, `NetworkClient` |
  | Implementation | `Default<Protocol>` or by technology (`HTTPNetworkClient`) |
  | DTO / request / SwiftData model | `<Name>DTO` / `<Name>Request` / `Cached<Name>`, `<Name>Record` |
  | UI model / ViewModel / mapper | `<Thing>Item` / `<Screen>ViewModel` / `<Screen>PresentationMapper` |
  | Test / test double | `<Type>Tests` / `Stub<X>`, `Gated<X>`, `Fixtures` |
- Prefer plain, readable code over clever one-liners: a `for` loop over `Dictionary(uniquingKeysWith:)` tricks, `guard let` over `Optional.map(function)`, a copy-and-modify (`var copy = self`) over rebuilding nested structs by hand. Derive values (computed properties) instead of storing two fields that must stay in sync.
- Comments: a `///` doc comment on every non-trivial type and function; complex logic gets the AI marker (`ai-logic-marker.md`) and, where asked, line comments `// <what>` + `// Output: <example result>`.
- Every View has a `#Preview` with sample data; full-screen previews use `AppContainer().make<Screen>ViewModel()`.
