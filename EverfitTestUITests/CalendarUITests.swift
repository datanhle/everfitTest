import XCTest

/// End-to-end flow of the calendar screen against the real API (`.claude/rules/ui-testing.md`).
/// Expected values come from `GET /workouts` fetched by the test and today's real date.
@MainActor
final class CalendarUITests: XCTestCase {
    private var app: XCUIApplication!
    private var screen: CalendarScreen!
    private var workouts: [APIWorkout] = []

    override func setUp() async throws {
        continueAfterFailure = false
        workouts = try await WorkoutsAPI.fetch()
        app = XCUIApplication.launchForUITesting()
        screen = CalendarScreen(app: app)
    }

    // MARK: - Structure

    func testWeekShowsSevenDaysMondayToSunday() {
        XCTAssertTrue(screen.dates.firstMatch.waitForExistence(timeout: CalendarScreen.timeout))

        let labels = screen.allDates().map(\.label)

        XCTAssertEqual(labels.count, 7)
        for (index, label) in labels.enumerated() {
            XCTAssertTrue(label.hasPrefix(TestWeek.weekdayTexts[index]), "Row \(index) is \"\(label)\"")
            XCTAssertTrue(label.hasSuffix(" \(TestWeek.dayNumbers[index])") || label.hasSuffix(",\(TestWeek.dayNumbers[index])"),
                          "Row \(index) is \"\(label)\", expected day \(TestWeek.dayNumbers[index])")
        }
    }

    func testOnlyTodayIsMarkedToday() {
        XCTAssertTrue(screen.dates.firstMatch.waitForExistence(timeout: CalendarScreen.timeout))

        let dates = screen.allDates()

        let todayRows = dates.indices.filter { dates[$0].value == "Today" }
        XCTAssertEqual(todayRows, [TestWeek.todayIndex])
    }

    // MARK: - First load

    func testFirstLaunchShowsLoadingThenWorkouts() throws {
        try XCTSkipIf(workouts.isEmpty, "API returned no workouts this run")

        // The dates are there from the start, before any data.
        XCTAssertTrue(screen.dates.firstMatch.waitForExistence(timeout: CalendarScreen.timeout))
        // No cache on this launch: the indicator may already be gone on a fast network, but never stays.
        screen.waitForWorkouts(workouts)

        XCTAssertFalse(screen.loading.exists)
    }

    // MARK: - Content vs API

    func testEveryAPIWorkoutShowsNameAndExerciseCountOnItsDay() throws {
        try XCTSkipIf(workouts.isEmpty, "API returned no workouts this run")
        screen.waitForWorkouts(workouts)

        for workout in workouts.sorted(by: { $0.day < $1.day }) {
            let card = screen.scrollTo(screen.card(workout.id))

            XCTAssertTrue(card.exists, "No card for \(workout.id)")
            // Full name is read by VoiceOver even when the visible text is truncated with "…".
            XCTAssertTrue(card.label.hasPrefix("\(workout.title), "), "Card \(workout.id) is \"\(card.label)\"")
            XCTAssertTrue(card.label.hasSuffix(", \(workout.exerciseCountText)"), "Card \(workout.id) is \"\(card.label)\"")
            XCTAssertEqual(screen.weekdayText(ofRowContaining: card), TestWeek.weekdayTexts[workout.day], "Card \(workout.id) is on the wrong day")
        }
    }

    // MARK: - Rules on screen

    func testStatusFollowsTheDate() throws {
        try XCTSkipIf(workouts.isEmpty, "API returned no workouts this run")
        screen.waitForWorkouts(workouts)

        for workout in workouts.sorted(by: { $0.day < $1.day }) {
            let card = screen.scrollTo(screen.card(workout.id))

            XCTAssertEqual(card.label, TestWeek.expectedLabel(of: workout))
            XCTAssertEqual(screen.isTappable(workout.id), TestWeek.relation(ofDay: workout.day) != .future,
                           "Card \(workout.id): only past and today are tappable")
        }
    }

    // MARK: - User action

    func testTapMarksAndUnmarksWorkout() throws {
        let workout = try XCTUnwrap(
            workouts.first { TestWeek.relation(ofDay: $0.day) != .future },
            "No past or today workout this week"
        )
        let isCompleted = workout.status == 2
        screen.waitForWorkouts(workouts)
        let card = screen.scrollTo(screen.card(workout.id))

        card.tap()
        screen.waitForLabel(card, toBe: TestWeek.expectedLabel(of: workout, completed: !isCompleted))

        card.tap()
        screen.waitForLabel(card, toBe: TestWeek.expectedLabel(of: workout, completed: isCompleted))
    }

    func testFutureWorkoutIsReadOnly() throws {
        guard let workout = workouts.first(where: { TestWeek.relation(ofDay: $0.day) == .future }) else {
            throw XCTSkip("No future workout this week (today is \(TestWeek.weekdayTexts[TestWeek.todayIndex]))")
        }
        screen.waitForWorkouts(workouts)
        let card = screen.scrollTo(screen.card(workout.id))
        let before = card.label

        card.tap()

        XCTAssertFalse(screen.isTappable(workout.id))
        XCTAssertEqual(card.label, before)
        XCTAssertEqual(before, TestWeek.expectedLabel(of: workout))
    }

    // MARK: - Refresh

    func testPullToRefreshKeepsWorkoutsAndToggles() throws {
        let workout = try XCTUnwrap(
            workouts.first { TestWeek.relation(ofDay: $0.day) != .future },
            "No past or today workout this week"
        )
        let toggled = TestWeek.expectedLabel(of: workout, completed: workout.status != 2)
        screen.waitForWorkouts(workouts)
        let card = screen.card(workout.id)
        XCTAssertTrue(card.isHittable, "Pick a workout near the top so the list does not need to scroll")
        card.tap()
        screen.waitForLabel(card, toBe: toggled)

        screen.pullToRefresh()

        // The refreshed API data must not undo the user's toggle.
        let reverted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", toggled), object: card)
        reverted.isInverted = true
        wait(for: [reverted], timeout: 5)
        XCTAssertTrue(card.exists)
        XCTAssertEqual(card.label, toggled)
    }
}
