import Foundation

/// Composition root: the one place that creates objects and wires them together.
/// Shared infrastructure is created once; each screen gets a `make…` method.
final class AppContainer {
    private let networkClient: NetworkClient = HTTPNetworkClient()
    /// UI tests launch with `-uiTesting`: an in-memory store, so every launch starts with no cache and no toggles.
    private let store = SwiftDataStore(modelContainer: SwiftDataStack.makeContainer(
        inMemory: ProcessInfo.processInfo.arguments.contains("-uiTesting")
    ))
    private let dateProvider: DateProvider = SystemDateProvider()

    /// Repository → use cases → ViewModel.
    func makeCalendarViewModel() -> CalendarViewModel {
        let repository = DefaultWorkoutRepository(networkClient: networkClient, store: store)
        return CalendarViewModel(
            loadSchedule: DefaultLoadWeeklyScheduleUseCase(repository: repository, dateProvider: dateProvider),
            toggleCompletion: DefaultToggleWorkoutCompletionUseCase(repository: repository)
        )
    }
}
